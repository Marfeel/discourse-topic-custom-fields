import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { alias } from "@ember/object/computed";
import { service } from "@ember/service";
import TopicCustomFieldInput from "../../components/topic-custom-field-input";

export default class TopicCustomFieldComposer extends Component {
  @service siteSettings;

  @tracked fieldValue;

  @alias("siteSettings.topic_custom_field_name") fieldName;
  @alias("args.outletArgs.model") composerModel;
  @alias("composerModel.topic") topic;

  constructor() {
    super(...arguments);

    if (
      !this.composerModel[this.fieldName] &&
      this.topic &&
      this.topic[this.fieldName]
    ) {
      this.composerModel.set(this.fieldName, this.topic[this.fieldName]);
    }

    this.fieldValue = this.composerModel.get(this.fieldName);
  }

  @action
  onChangeField(fieldValue) {
    this.composerModel.set(this.fieldName, fieldValue);
    this.fieldValue = fieldValue;
  }

  <template>
    <TopicCustomFieldInput
      @fieldValue={{this.fieldValue}}
      @onChangeField={{this.onChangeField}}
    />
  </template>
}
