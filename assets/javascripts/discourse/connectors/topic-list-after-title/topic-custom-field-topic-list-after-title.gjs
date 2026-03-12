import Component from "@glimmer/component";
import { service } from "@ember/service";
import { i18n } from "discourse-i18n";

export default class TopicCustomFieldTopicListAfterTitle extends Component {
  @service siteSettings;

  get fieldName() {
    return this.siteSettings.topic_custom_field_name;
  }

  get fieldValue() {
    return this.args.outletArgs.topic.get(this.fieldName);
  }

  get showCustomField() {
    return !!this.fieldValue;
  }

  <template>
    {{#if this.showCustomField}}
      <span>|</span>
      <a
        href={{@outletArgs.topic.lastUnreadUrl}}
        class={{this.fieldName}}
        data-topic-id={{@outletArgs.topic.id}}
      >
        <span>{{i18n
            "topic_custom_field.label"
            field=this.fieldName
            value=this.fieldValue
          }}</span>
      </a>
    {{/if}}
  </template>
}
