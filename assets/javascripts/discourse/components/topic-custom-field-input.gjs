import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import DateInput from "discourse/components/date-input";
import { eq } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";

export default class TopicCustomFieldInput extends Component {
  handleCheckboxChange = (event) => {
    this.args.onChangeField(event.target.checked);
  };

  handleInputChange = (event) => {
    this.args.onChangeField(event.target.value);
  };

  handleDateChange = (momentDate) => {
    this.args.onChangeField(momentDate ? momentDate.format("YYYY-MM-DD") : null);
  };

  <template>
    <div class="topic-custom-field-row">
      <label class="topic-custom-field-label">{{@fieldName}}</label>

      {{#if (eq @fieldType "boolean")}}
        <label class="checkbox-label">
          <input
            type="checkbox"
            checked={{@fieldValue}}
            {{on "change" this.handleCheckboxChange}}
          />
        </label>
      {{else if (eq @fieldType "integer")}}
        <input
          type="number"
          value={{@fieldValue}}
          placeholder={{i18n "topic_custom_field.placeholder" field=@fieldName}}
          class="topic-custom-field-input small"
          {{on "change" this.handleInputChange}}
        />
      {{else if (eq @fieldType "date")}}
        <DateInput
          @date={{@fieldValue}}
          @onChange={{this.handleDateChange}}
          class="topic-custom-field-date"
        />
      {{else}}
        <input
          type="text"
          value={{@fieldValue}}
          placeholder={{i18n "topic_custom_field.placeholder" field=@fieldName}}
          class="topic-custom-field-input large"
          {{on "change" this.handleInputChange}}
        />
      {{/if}}
    </div>
  </template>
}
