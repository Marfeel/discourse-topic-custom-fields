import { withPluginApi } from "discourse/lib/plugin-api";

const FIELD_PREFIX = "topic_custom_field_";
const CONFIG_KEY = "topic_custom_fields_config";

export default {
  name: "topic-custom-field-intializer",
  initialize(container) {
    const siteSettings = container.lookup("service:site-settings");
    if (!siteSettings.topic_custom_field_enabled) {
      return;
    }

    const site = container.lookup("service:site");
    const categories = site.categories || [];

    const fieldNames = new Set();
    categories.forEach((cat) => {
      const raw = cat.custom_fields?.[CONFIG_KEY];
      if (!raw) {
        return;
      }
      const config = typeof raw === "string" ? JSON.parse(raw) : raw;
      if (!Array.isArray(config)) {
        return;
      }
      config.forEach((field) => {
        if (field.name) {
          fieldNames.add(field.name);
        }
      });
    });

    withPluginApi((api) => {
      fieldNames.forEach((name) => {
        const key = `${FIELD_PREFIX}${name}`;
        api.serializeOnCreate(key);
        api.serializeToDraft(key);
        api.serializeToTopic(key, `topic.${key}`);
      });
    });
  },
};
