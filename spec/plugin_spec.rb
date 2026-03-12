# frozen_string_literal: true

require "rails_helper"

describe "TopicCustomFields" do
  fab!(:category)
  fab!(:user) { Fabricate(:user, trust_level: TrustLevel[4]) }
  fab!(:admin)

  before { SiteSetting.topic_custom_field_enabled = true }

  describe "category config" do
    it "stores and retrieves field config as JSON" do
      config = [{ "name" => "price", "type" => "integer" }]
      category.custom_fields["topic_custom_fields_config"] = config.to_json
      category.save!
      category.reload

      result = category.custom_fields["topic_custom_fields_config"]
      parsed = result.is_a?(String) ? JSON.parse(result) : result
      expect(parsed).to eq(config)
    end

    it "serializes config to category response" do
      config = [{ "name" => "deadline", "type" => "date" }]
      category.custom_fields["topic_custom_fields_config"] = config.to_json
      category.save!

      serializer =
        CategorySerializer.new(category, scope: Guardian.new(admin), root: false)
      json = serializer.as_json
      expect(json[:custom_fields]["topic_custom_fields_config"]).to be_present
    end
  end

  describe "topic creation with custom fields" do
    fab!(:category_with_fields) { Fabricate(:category) }

    before do
      config = [
        { "name" => "price", "type" => "integer" },
        { "name" => "deadline", "type" => "date" },
        { "name" => "featured", "type" => "boolean" },
        { "name" => "notes", "type" => "string" },
      ]
      category_with_fields.custom_fields["topic_custom_fields_config"] = config.to_json
      category_with_fields.save!
    end

    it "saves custom fields on topic creation" do
      post =
        PostCreator.create!(
          user,
          title: "Topic with custom fields test title",
          raw: "This is the body of the topic with custom fields",
          category: category_with_fields.id,
          topic_custom_field_price: "42",
          topic_custom_field_deadline: "2026-06-01",
          topic_custom_field_featured: "true",
          topic_custom_field_notes: "some notes",
        )

      topic = post.topic
      topic.reload

      expect(topic.custom_fields["topic_custom_field_price"]).to eq("42")
      expect(topic.custom_fields["topic_custom_field_deadline"]).to eq("2026-06-01")
      expect(topic.custom_fields["topic_custom_field_featured"]).to eq("true")
      expect(topic.custom_fields["topic_custom_field_notes"]).to eq("some notes")
    end

    it "ignores fields not in category config" do
      post =
        PostCreator.create!(
          user,
          title: "Topic ignoring extra fields test",
          raw: "This is the body of the topic",
          category: category_with_fields.id,
          topic_custom_field_price: "42",
          topic_custom_field_unknown: "should be ignored",
        )

      topic = post.topic
      topic.reload

      expect(topic.custom_fields["topic_custom_field_price"]).to eq("42")
      expect(topic.custom_fields["topic_custom_field_unknown"]).to be_nil
    end

    it "does nothing when category has no config" do
      post =
        PostCreator.create!(
          user,
          title: "Topic without custom fields config",
          raw: "This is the body of the topic",
          category: category.id,
          topic_custom_field_price: "42",
        )

      topic = post.topic
      topic.reload

      expect(topic.custom_fields["topic_custom_field_price"]).to be_nil
    end
  end

  describe "topic serialization" do
    fab!(:category_with_fields) { Fabricate(:category) }
    fab!(:topic) { Fabricate(:topic, category: category_with_fields) }

    before do
      config = [
        { "name" => "price", "type" => "integer" },
        { "name" => "deadline", "type" => "date" },
      ]
      category_with_fields.custom_fields["topic_custom_fields_config"] = config.to_json
      category_with_fields.save!

      topic.custom_fields["topic_custom_field_price"] = "42"
      topic.custom_fields["topic_custom_field_deadline"] = "2026-06-01"
      topic.save_custom_fields
    end

    it "includes custom fields data in topic view" do
      topic_view = TopicView.new(topic, admin)
      serializer = TopicViewSerializer.new(topic_view, scope: Guardian.new(admin), root: false)
      json = serializer.as_json

      expect(json[:topic_custom_fields_data]).to eq(
        "price" => "42",
        "deadline" => "2026-06-01",
      )
    end

    it "returns empty hash when category has no config" do
      topic_no_config = Fabricate(:topic, category: category)
      topic_view = TopicView.new(topic_no_config, admin)
      serializer = TopicViewSerializer.new(topic_view, scope: Guardian.new(admin), root: false)
      json = serializer.as_json

      expect(json[:topic_custom_fields_data]).to eq({})
    end
  end

  describe "topic editing" do
    fab!(:category_with_fields) { Fabricate(:category) }
    fab!(:topic) { Fabricate(:topic, category: category_with_fields, user: user) }
    fab!(:post) { Fabricate(:post, topic: topic, user: user) }

    before do
      config = [{ "name" => "price", "type" => "integer" }]
      category_with_fields.custom_fields["topic_custom_fields_config"] = config.to_json
      category_with_fields.save!

      topic.custom_fields["topic_custom_field_price"] = "42"
      topic.save_custom_fields
    end

    it "updates custom fields on topic edit" do
      revisor = PostRevisor.new(post, topic)
      revisor.revise!(user, { topic_custom_field_price: "99" }, revised_at: Time.now)

      topic.reload
      expect(topic.custom_fields["topic_custom_field_price"]).to eq("99")
    end
  end

  describe "validation" do
    it "rejects invalid field names in config" do
      config = [{ "name" => "invalid name!", "type" => "string" }]
      category.custom_fields["topic_custom_fields_config"] = config.to_json

      expect(category.valid?).to eq(false)
      expect(category.errors[:base]).to be_present
    end

    it "rejects invalid field types in config" do
      config = [{ "name" => "valid_name", "type" => "invalid_type" }]
      category.custom_fields["topic_custom_fields_config"] = config.to_json

      expect(category.valid?).to eq(false)
    end

    it "rejects more than 10 fields" do
      config = (1..11).map { |i| { "name" => "field_#{i}", "type" => "string" } }
      category.custom_fields["topic_custom_fields_config"] = config.to_json

      expect(category.valid?).to eq(false)
    end

    it "rejects type conflicts with other categories" do
      other_category = Fabricate(:category)
      other_category.custom_fields["topic_custom_fields_config"] =
        [{ "name" => "price", "type" => "integer" }].to_json
      other_category.save!

      config = [{ "name" => "price", "type" => "string" }]
      category.custom_fields["topic_custom_fields_config"] = config.to_json

      expect(category.valid?).to eq(false)
    end
  end
end
