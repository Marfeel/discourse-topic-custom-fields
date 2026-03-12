# frozen_string_literal: true

# name: discourse-topic-custom-fields
# about: Per-category custom fields for Discourse topics
# version: 2.0
# authors: Angus McLeod
# contact email: angus@pavilion.tech
# url: https://github.com/pavilionedu/discourse-topic-custom-fields

enabled_site_setting :topic_custom_field_enabled
register_asset "stylesheets/common.scss"

after_initialize do
  module ::TopicCustomFields
    FIELD_PREFIX = "topic_custom_field_"
    CONFIG_KEY = "topic_custom_fields_config"
    VALID_TYPES = %w[string integer boolean date].freeze
    MAX_FIELDS = 10
    VALID_NAME_REGEX = /\A[a-zA-Z0-9_]+\z/

    def self.category_config(category)
      return [] unless category
      raw = category.custom_fields[CONFIG_KEY]
      return [] if raw.blank?
      config = raw.is_a?(String) ? JSON.parse(raw) : raw
      config.is_a?(Array) ? config : []
    rescue JSON::ParserError
      []
    end

    def self.register_field_tracking(field_name, field_type)
      key = "#{FIELD_PREFIX}#{field_name}"
      return if PostRevisor.tracked_topic_fields.key?(key.to_sym)

      PostRevisor.track_topic_field(key.to_sym) do |tc, value|
        tc.record_change(key, tc.topic.custom_fields[key], value)
        tc.topic.custom_fields[key] = value.present? ? value : nil
      end
    end
  end

  register_category_custom_field_type(TopicCustomFields::CONFIG_KEY, :json)
  register_preloaded_category_custom_fields(TopicCustomFields::CONFIG_KEY)

  reloadable_patch do
    Category.class_eval do
      validate :validate_topic_custom_fields_config
      after_save :register_topic_custom_field_tracking

      def validate_topic_custom_fields_config
        raw = custom_fields[TopicCustomFields::CONFIG_KEY]
        return if raw.blank?

        config =
          begin
            raw.is_a?(String) ? JSON.parse(raw) : raw
          rescue JSON::ParserError
            errors.add(:base, "Invalid JSON in topic custom fields config")
            return
          end

        return unless config.is_a?(Array)

        if config.size > TopicCustomFields::MAX_FIELDS
          errors.add(
            :base,
            I18n.t("topic_custom_field.errors.max_fields"),
          )
          return
        end

        config.each do |field|
          name = field["name"]
          type = field["type"]

          unless name.present? && name.match?(TopicCustomFields::VALID_NAME_REGEX)
            errors.add(
              :base,
              I18n.t("topic_custom_field.errors.invalid_field_name", name: name),
            )
          end

          unless TopicCustomFields::VALID_TYPES.include?(type)
            errors.add(
              :base,
              I18n.t("topic_custom_field.errors.invalid_field_type", type: type),
            )
          end
        end

        return if errors.any?

        config.each do |field|
          name = field["name"]
          type = field["type"]

          Category
            .where.not(id: id)
            .joins(
              "INNER JOIN category_custom_fields ON category_custom_fields.category_id = categories.id",
            )
            .where("category_custom_fields.name = ?", TopicCustomFields::CONFIG_KEY)
            .find_each do |other_cat|
              other_config = other_cat.custom_fields[TopicCustomFields::CONFIG_KEY]
              other_config =
                other_config.is_a?(String) ? JSON.parse(other_config) : other_config
              next unless other_config.is_a?(Array)

              match = other_config.find { |f| f["name"] == name }
              if match && match["type"] != type
                errors.add(
                  :base,
                  I18n.t(
                    "topic_custom_field.errors.type_conflict",
                    name: name,
                    type: match["type"],
                  ),
                )
                break
              end
            end
        end
      end

      def register_topic_custom_field_tracking
        config = TopicCustomFields.category_config(self)
        config.each do |field|
          TopicCustomFields.register_field_tracking(field["name"], field["type"])
        end
      end
    end
  end

  on(:topic_created) do |topic, opts, user|
    next unless SiteSetting.topic_custom_field_enabled
    config = TopicCustomFields.category_config(topic.category)
    next if config.empty?

    changed = false
    config.each do |field|
      key = "#{TopicCustomFields::FIELD_PREFIX}#{field["name"]}"
      value = opts[key.to_sym]
      next if value.nil?

      topic.custom_fields[key] = value
      changed = true
    end
    topic.save_custom_fields if changed
  end

  begin
    if ActiveRecord::Base.connection.table_exists?(:category_custom_fields)
      Category
        .joins(
          "INNER JOIN category_custom_fields ON category_custom_fields.category_id = categories.id",
        )
        .where("category_custom_fields.name = ?", TopicCustomFields::CONFIG_KEY)
        .find_each do |cat|
          config = TopicCustomFields.category_config(cat)
          config.each do |field|
            TopicCustomFields.register_field_tracking(field["name"], field["type"])
          end
        end
    end
  rescue ActiveRecord::NoDatabaseError, PG::ConnectionBad
    # Skip during db:create or when database is not available
  end

  add_to_serializer(:topic_view, :topic_custom_fields_data) do
    config = TopicCustomFields.category_config(object.topic.category)
    return {} if config.empty?

    result = {}
    config.each do |field|
      key = "#{TopicCustomFields::FIELD_PREFIX}#{field["name"]}"
      value = object.topic.custom_fields[key]
      result[field["name"]] = value unless value.nil?
    end
    result
  end

  add_to_serializer(:topic_view, :topic_custom_fields_config) do
    TopicCustomFields.category_config(object.topic.category)
  end
end
