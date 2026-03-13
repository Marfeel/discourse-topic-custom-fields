import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn, get } from "@ember/helper";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { service } from "@ember/service";
import Category from "discourse/models/category";
import Composer from "discourse/models/composer";
import TopicCustomFieldInput from "../../components/topic-custom-field-input";

const FIELD_PREFIX = "topic_custom_field_";
const CONFIG_KEY = "topic_custom_fields_config";

const _registeredFields = new Set();

export default class TopicCustomFieldComposer extends Component {
  @service siteSettings;

  @tracked fieldValues = {};

  _lastCategoryId = null;

  get composerModel() {
    return this.args.outletArgs.model;
  }

  get category() {
    const categoryId = this.composerModel?.categoryId;
    return categoryId ? Category.findById(categoryId) : null;
  }

  get fieldsConfig() {
    if (!this.siteSettings.topic_custom_field_enabled || !this.category) {
      return [];
    }

    const raw = this.category.custom_fields?.[CONFIG_KEY];
    if (!raw) {
      return [];
    }
    const config = typeof raw === "string" ? JSON.parse(raw) : raw;
    if (!Array.isArray(config)) {
      return [];
    }

    return config;
  }

  ensureFieldsSerialized(config) {
    config.forEach((field) => {
      if (_registeredFields.has(field.name)) {
        return;
      }
      const key = `${FIELD_PREFIX}${field.name}`;
      Composer.serializeOnCreate(key);
      Composer.serializeToDraft(key);
      Composer.serializeToTopic(key, `topic.${key}`);
      _registeredFields.add(field.name);
    });
  }

  @action
  ensureFieldValues() {
    const category = this.category;
    if (!category) {
      return;
    }

    const currentCategoryId = category.id;
    if (this._lastCategoryId !== null && this._lastCategoryId !== currentCategoryId) {
      this.fieldValues = {};
    }
    this._lastCategoryId = currentCategoryId;

    const config = this.fieldsConfig;
    this.ensureFieldsSerialized(config);

    const topic = this.composerModel?.topic;
    const topicData = topic?.topic_custom_fields_data || {};
    const values = { ...this.fieldValues };
    let changed = false;

    config.forEach((field) => {
      if (values[field.name] !== undefined) {
        return;
      }
      const key = `${FIELD_PREFIX}${field.name}`;
      const existing =
        this.composerModel?.get(key) ?? topic?.get(key) ?? topicData[field.name];
      if (existing != null) {
        values[field.name] = existing;
        this.composerModel?.set(key, existing);
        changed = true;
      }
    });

    if (changed) {
      this.fieldValues = values;
    }
  }

  @action
  onChangeField(fieldName, value) {
    const key = `${FIELD_PREFIX}${fieldName}`;
    this.composerModel?.set(key, value);
    this.fieldValues = { ...this.fieldValues, [fieldName]: value };
  }

  <template>
    <div
      class="topic-custom-field-composer-fields"
      {{didInsert this.ensureFieldValues}}
      {{didUpdate this.ensureFieldValues this.fieldsConfig}}
    >
      {{#each this.fieldsConfig as |field|}}
        <TopicCustomFieldInput
          @fieldName={{field.name}}
          @fieldType={{field.type}}
          @fieldValue={{get this.fieldValues field.name}}
          @onChangeField={{fn this.onChangeField field.name}}
        />
      {{/each}}
    </div>
  </template>
}
