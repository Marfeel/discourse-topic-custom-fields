# Discourse Topic Custom Fields

A Discourse plugin that lets admins define custom fields per category. Fields appear in the topic composer and topic view.

Originally based on [pavilionedu/discourse-topic-custom-fields](https://github.com/pavilionedu/discourse-topic-custom-fields).

## Features

- Define up to 10 custom fields per category from the category settings page
- Supported field types: **Text**, **Number**, **Checkbox**, **Date**
- Fields display as badges below the topic title
- Fields appear in the composer when creating or editing a topic
- Master toggle via the `topic_custom_field_enabled` site setting

## Installation

Follow the standard [Discourse plugin installation guide](https://meta.discourse.org/t/install-plugins-in-discourse/19157):

```
cd /var/discourse
./launcher enter app
cd /src/plugins
git clone https://github.com/your-org/discourse-topic-custom-fields.git
cd /src
RAILS_ENV=production bundle exec rake assets:precompile
exit
./launcher restart app
```

## Configuration

1. Enable the plugin in **Admin > Settings** by toggling `topic_custom_field_enabled`
2. Go to any **Category > Settings** and scroll to **Topic Custom Fields**
3. Add fields with a name and type
4. Save the category

Fields will appear in the composer for that category and on topics created within it.

## Field Types

| Type | Composer Input | Display |
|------|---------------|---------|
| Text | Text input | Value as-is |
| Number | Number input | Value as-is |
| Checkbox | Checkbox | Yes / No |
| Date | Date picker | YYYY-MM-DD |

## Constraints

- Field names: letters, numbers, and underscores only
- Max 10 fields per category
- Same field name across categories must use the same type
- All fields are optional (no required field validation)

## License

MIT
