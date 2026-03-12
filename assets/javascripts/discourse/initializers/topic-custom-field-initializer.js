import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "topic-custom-field-intializer",
  initialize(container) {
    const siteSettings = container.lookup("service:site-settings");
    const fieldName = siteSettings.topic_custom_field_name;

    withPluginApi((api) => {
      api.serializeOnCreate(fieldName);
      api.serializeToDraft(fieldName);
      api.serializeToTopic(fieldName, `topic.${fieldName}`);
    });
  },
};
