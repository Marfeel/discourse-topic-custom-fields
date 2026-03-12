import Component from "@glimmer/component";
import { service } from "@ember/service";
import { i18n } from "discourse-i18n";

export default class TopicCustomFieldTopicTitle extends Component {
  @service siteSettings;

  get fieldName() {
    return this.siteSettings.topic_custom_field_name;
  }

  get fieldValue() {
    return this.args.outletArgs.model.get(this.fieldName);
  }

  <template>
    {{#unless @outletArgs.model.editingTopic}}
      <span>{{i18n
          "topic_custom_field.label"
          field=this.fieldName
          value=this.fieldValue
        }}</span>
    {{/unless}}
  </template>
}
