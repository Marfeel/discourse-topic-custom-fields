import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { alias } from "@ember/object/computed";
import { service } from "@ember/service";
import TopicCustomFieldInput from "../../components/topic-custom-field-input";

export default class TopicCustomFieldEditTopic extends Component {
  @service siteSettings;

  @tracked fieldValue;

  @alias("siteSettings.topic_custom_field_name") fieldName;

  constructor() {
    super(...arguments);
    this.fieldValue = this.args.outletArgs.model.get(this.fieldName);
  }

  @action
  onChangeField(fieldValue) {
    this.args.outletArgs.buffered.set(this.fieldName, fieldValue);
    this.fieldValue = fieldValue;
  }

  <template>
    <TopicCustomFieldInput
      @fieldValue={{this.fieldValue}}
      @onChangeField={{this.onChangeField}}
    />
  </template>
}
