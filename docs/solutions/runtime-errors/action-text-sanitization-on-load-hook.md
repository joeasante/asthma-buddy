---
title: "ActionText Sanitization Initializer: Use on_load Hook, Not after_initialize"
problem_type: "runtime-errors"
severity: "high"
tags: ["ActionText", "sanitization", "initializers", "Rails hooks", "nil-safety", "security", "Lexxy"]
components: ["ActionText::ContentHelper", "ActiveSupport.on_load", "config/initializers"]
solved: "2026-03-10"
---

# ActionText Sanitization Initializer: Use `on_load` Hook, Not `after_initialize`

## Problem Symptom

App crashes on boot with:

```
NoMethodError: undefined method 'delete' for nil
  from config/initializers/action_text_sanitization.rb
```

## Root Cause

`Rails.application.config.after_initialize` fires before ActionText has fully loaded its
`allowed_attributes` and `allowed_tags` class variables. At that point both return `nil`,
so calling `.delete("style")` on nil raises `NoMethodError`.

## Failed Approach

```ruby
# config/initializers/action_text_sanitization.rb  ← WRONG
Rails.application.config.after_initialize do
  ActionText::ContentHelper.allowed_attributes.delete("style")  # nil.delete → boom
  ActionText::ContentHelper.allowed_tags.delete("embed")
end
```

## Working Solution

```ruby
# config/initializers/action_text_sanitization.rb
# frozen_string_literal: true

# Restrict ActionText/Lexxy sanitization to prevent user-controlled CSS and
# embedded resources in medical notes.
#
# Lexxy adds "style" to allowed_attributes and "embed" to allowed_tags.
# Both open exfiltration and content-injection vectors in a health app.
# This hook runs after ActionText has been fully initialized.

ActiveSupport.on_load(:action_text_content) do
  ActionText::ContentHelper.allowed_attributes&.delete("style")
  ActionText::ContentHelper.allowed_tags&.delete("embed")
end
```

### Why It Works

- `ActiveSupport.on_load(:action_text_content)` fires **after** ActionText initializes its
  `allowed_attributes` / `allowed_tags` sets — the correct lifecycle hook.
- `&.` (safe navigation) is a defensive guard: if the set is nil for any reason, the call
  is a no-op instead of a crash.
- Inside the block `self` is the ActionText content class, but referencing
  `ActionText::ContentHelper` explicitly is also valid and equally safe.

## Rails Initialization Hook Reference

| Hook | Fires when | Use for |
|------|-----------|---------|
| `after_initialize` | App fully booted | Global app config (not framework internals) |
| `on_load(:action_text_content)` | ActionText::ContentHelper loaded | Modifying AT sanitization |
| `on_load(:active_record)` | ActiveRecord loaded | Custom AR extensions |
| `on_load(:action_controller)` | ActionController loaded | Controller-level extensions |

## Prevention Checklist

- [ ] Never use `after_initialize` to modify ActionText class variables
- [ ] Always use `ActiveSupport.on_load(:action_text_content)` for AT sanitization changes
- [ ] Use `&.delete` / `&.add` instead of bare `.delete` / `.add` as a nil guard
- [ ] Boot the app (`bin/rails server`) after adding any ActionText initializer to verify no crash

## Detection Tests

```ruby
# test/integration/action_text_sanitization_test.rb
class ActionTextSanitizationTest < ActionDispatch::IntegrationTest
  test "style attribute is removed from allowed_attributes" do
    assert_not ActionText::ContentHelper.allowed_attributes.include?("style")
  end

  test "embed tag is removed from allowed_tags" do
    assert_not ActionText::ContentHelper.allowed_tags.include?("embed")
  end

  test "sanitizer strips inline styles from content" do
    content = ActionText::Content.new('<p style="color:red">Text</p>')
    assert_not content.to_html.include?("style")
  end
end
```

## Context

This pattern appears in `config/initializers/action_text_sanitization.rb` in the asthma-buddy app.
The Lexxy gem (rich text editor replacing Trix) adds `"style"` to allowed attributes by default.
For a health app handling medical notes, allowing arbitrary inline CSS opens XSS / data exfiltration
vectors that must be closed at the ActionText sanitization layer.
