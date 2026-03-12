import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn, get } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import TopicCustomFieldInput from "../../components/topic-custom-field-input";

const FIELD_PREFIX = "topic_custom_field_";

export default class TopicCustomFieldEditTopic extends Component {
  @service siteSettings;

  @tracked fieldValues = {};

  constructor() {
    super(...arguments);
    this.initFieldValues();
  }

  get topic() {
    return this.args.outletArgs.model;
  }

  get buffered() {
    return this.args.outletArgs.buffered;
  }

  get fieldsConfig() {
    return this.topic?.topic_custom_fields_config || [];
  }

  initFieldValues() {
    const data = this.topic?.topic_custom_fields_data || {};
    const values = {};
    this.fieldsConfig.forEach((field) => {
      if (data[field.name] != null) {
        values[field.name] = data[field.name];
      }
    });
    this.fieldValues = values;
  }

  @action
  onChangeField(fieldName, value) {
    const key = `${FIELD_PREFIX}${fieldName}`;
    this.buffered?.set(key, value);
    this.fieldValues = { ...this.fieldValues, [fieldName]: value };
  }

  <template>
    {{#if this.siteSettings.topic_custom_field_enabled}}
      {{#each this.fieldsConfig as |field|}}
        <TopicCustomFieldInput
          @fieldName={{field.name}}
          @fieldType={{field.type}}
          @fieldValue={{get this.fieldValues field.name}}
          @onChangeField={{fn this.onChangeField field.name}}
        />
      {{/each}}
    {{/if}}
  </template>
}
