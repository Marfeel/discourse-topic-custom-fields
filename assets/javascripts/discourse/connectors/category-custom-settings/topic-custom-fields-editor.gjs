import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { concat, fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import withEventValue from "discourse/helpers/with-event-value";
import { eq } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";

const VALID_TYPES = ["string", "integer", "boolean", "date"];
const MAX_FIELDS = 10;

class FieldRow {
  @tracked name;
  @tracked type;

  constructor(name = "", type = "string") {
    this.name = name;
    this.type = type;
  }
}

export default class TopicCustomFieldsEditor extends Component {
  @service siteSettings;

  @tracked fields = this.loadFields();

  get customFields() {
    return this.args.outletArgs.category.custom_fields;
  }

  get canAddField() {
    return this.fields.length < MAX_FIELDS;
  }

  loadFields() {
    const raw = this.customFields?.topic_custom_fields_config;
    if (!raw) {
      return [];
    }
    const config = typeof raw === "string" ? JSON.parse(raw) : raw;
    if (!Array.isArray(config)) {
      return [];
    }
    return config.map((f) => new FieldRow(f.name, f.type));
  }

  syncToCategory() {
    const config = this.fields
      .filter((f) => f.name.trim() !== "")
      .map((f) => ({ name: f.name.trim(), type: f.type }));
    this.customFields.topic_custom_fields_config = JSON.stringify(config);
  }

  @action
  addField() {
    if (!this.canAddField) {
      return;
    }
    this.fields = [...this.fields, new FieldRow()];
    this.syncToCategory();
  }

  @action
  removeField(field) {
    this.fields = this.fields.filter((f) => f !== field);
    this.syncToCategory();
  }

  @action
  updateFieldName(field, value) {
    field.name = value;
    this.syncToCategory();
  }

  @action
  updateFieldType(field, value) {
    field.type = value;
    this.syncToCategory();
  }

  <template>
    {{#if this.siteSettings.topic_custom_field_enabled}}
      <div class="category-custom-settings-outlet topic-custom-fields-editor">
        <h3>{{i18n "topic_custom_field.section_title"}}</h3>

        {{#each this.fields as |field|}}
          <div class="topic-custom-fields-editor__row">
            <input
              type="text"
              value={{field.name}}
              placeholder={{i18n "topic_custom_field.field_name"}}
              class="topic-custom-fields-editor__name"
              {{on "input" (withEventValue (fn this.updateFieldName field))}}
            />

            <select
              class="topic-custom-fields-editor__type"
              {{on "change" (withEventValue (fn this.updateFieldType field))}}
            >
              {{#each VALID_TYPES as |t|}}
                <option value={{t}} selected={{eq t field.type}}>
                  {{i18n (concat "topic_custom_field.types." t)}}
                </option>
              {{/each}}
            </select>

            <button
              type="button"
              class="btn btn-danger btn-small topic-custom-fields-editor__remove"
              {{on "click" (fn this.removeField field)}}
            >
              {{i18n "topic_custom_field.remove_field"}}
            </button>
          </div>
        {{/each}}

        {{#if this.canAddField}}
          <button
            type="button"
            class="btn btn-default btn-small topic-custom-fields-editor__add"
            {{on "click" this.addField}}
          >
            {{i18n "topic_custom_field.add_field"}}
          </button>
        {{else}}
          <p class="topic-custom-fields-editor__limit">
            {{i18n "topic_custom_field.max_fields_reached"}}
          </p>
        {{/if}}
      </div>
    {{/if}}
  </template>
}
