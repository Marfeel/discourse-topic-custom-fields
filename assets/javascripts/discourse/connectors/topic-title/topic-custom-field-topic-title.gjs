import Component from "@glimmer/component";
import { service } from "@ember/service";
import { i18n } from "discourse-i18n";

export default class TopicCustomFieldTopicTitle extends Component {
  @service siteSettings;

  get topic() {
    return this.args.outletArgs.model;
  }

  get fieldsData() {
    if (!this.siteSettings.topic_custom_field_enabled) {
      return [];
    }

    const data = this.topic?.topic_custom_fields_data;
    const config = this.topic?.topic_custom_fields_config;

    if (!data || !config || !Array.isArray(config)) {
      return [];
    }

    return config
      .filter((field) => data[field.name] != null)
      .map((field) => ({
        name: field.name,
        type: field.type,
        value: field.type === "boolean" ? (data[field.name] ? "Yes" : "No") : data[field.name],
      }));
  }

  <template>
    {{#unless @outletArgs.model.editingTopic}}
      {{#each this.fieldsData as |field|}}
        <span class="topic-custom-field-display">
          {{i18n "topic_custom_field.label" field=field.name value=field.value}}
        </span>
      {{/each}}
    {{/unless}}
  </template>
}
