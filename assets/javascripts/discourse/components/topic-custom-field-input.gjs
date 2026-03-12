import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { readOnly } from "@ember/object/computed";
import { service } from "@ember/service";
import { eq } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";

export default class TopicCustomFieldInput extends Component {
  @service siteSettings;

  @readOnly("siteSettings.topic_custom_field_name") fieldName;
  @readOnly("siteSettings.topic_custom_field_type") fieldType;

  handleCheckboxChange = (event) => {
    this.args.onChangeField(event.target.checked);
  };

  handleInputChange = (event) => {
    this.args.onChangeField(event.target.value);
  };

  <template>
    {{#if (eq this.fieldType "boolean")}}
      <input
        type="checkbox"
        checked={{@fieldValue}}
        {{on "change" this.handleCheckboxChange}}
      />
      <span>{{this.fieldName}}</span>
    {{/if}}

    {{#if (eq this.fieldType "integer")}}
      <input
        type="number"
        value={{@fieldValue}}
        placeholder={{i18n
          "topic_custom_field.placeholder"
          field=this.fieldName
        }}
        class="topic-custom-field-input small"
        {{on "change" this.handleInputChange}}
      />
    {{/if}}

    {{#if (eq this.fieldType "string")}}
      <input
        type="text"
        value={{@fieldValue}}
        placeholder={{i18n
          "topic_custom_field.placeholder"
          field=this.fieldName
        }}
        class="topic-custom-field-input large"
        {{on "change" this.handleInputChange}}
      />
    {{/if}}

    {{#if (eq this.fieldType "json")}}
      <textarea
        placeholder={{i18n
          "topic_custom_field.placeholder"
          field=this.fieldName
        }}
        class="topic-custom-field-textarea"
        {{on "change" this.handleInputChange}}
      >{{@fieldValue}}</textarea>
    {{/if}}
  </template>
}
