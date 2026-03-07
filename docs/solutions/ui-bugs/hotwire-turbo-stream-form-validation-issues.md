---
title: Hotwire Turbo Stream form validation — three interconnected issues
date: 2026-03-07
category: ui-bugs
tags: [rails, hotwire, turbo-stream, form-validation, enums, controller]
symptoms:
  - Browser shows native "please select an item in the list" tooltip instead of Rails inline errors
  - NoMethodError undefined method empty? for nil in index template after failed create
  - 4 validation errors displayed for 2 blank fields (duplicate messages per field)
components:
  - app/views/symptom_logs/_form.html.erb
  - app/controllers/symptom_logs_controller.rb
  - app/models/symptom_log.rb
  - test/models/symptom_log_test.rb
related_issues: []
---

# Hotwire Turbo Stream Form Validation Issues

Three interconnected issues encountered when building a Turbo Stream form with Rails enum fields. Each can appear independently but they often compound together.

---

## Issue 1: HTML `required` Attribute Blocks Turbo Stream Validation

### Symptom

Submitting an empty form shows the browser's native "please select an item in the list" tooltip instead of the intended inline Rails validation errors. The Turbo Stream error response never fires.

### Root Cause

`{ required: true }` on form selects and `required: true` on datetime fields cause the browser's HTML5 validation to intercept the submit event before the request reaches Rails. Turbo Stream error responses depend on the form submission completing a round-trip to the server. Browser-level validation short-circuits this entirely.

### Fix

Remove HTML `required` attributes from all inputs where Rails model validations are the source of truth.

```erb
<%# Before %>
<%= form.select :symptom_type, options, { include_blank: "Select..." }, { required: true } %>
<%= form.select :severity, options, { include_blank: "Select..." }, { required: true } %>
<%= form.datetime_local_field :recorded_at, required: true %>

<%# After %>
<%= form.select :symptom_type, options, { include_blank: "Select..." } %>
<%= form.select :severity, options, { include_blank: "Select..." } %>
<%= form.datetime_local_field :recorded_at %>
```

**Note:** `form_with` in Rails does NOT add `required` automatically — it must have been added explicitly. The model's `validate: true` enum and `presence: true` validations cover this server-side.

---

## Issue 2: `@symptom_logs` Nil in Create Failure Path

### Symptom

```
NoMethodError in SymptomLogs#create
undefined method 'empty?' for nil
Showing app/views/symptom_logs/index.html.erb where line #15 raised
```

Triggered by submitting an invalid form (after removing HTML `required` so Rails validation fires).

### Root Cause

The `create` action's failure branch calls `render :index` but doesn't set `@symptom_logs`. The `index` action sets it; `create` doesn't — so the template gets `nil`.

```ruby
# index action sets it:
def index
  @symptom_log = Current.user.symptom_logs.new(recorded_at: Time.current)
  @symptom_logs = Current.user.symptom_logs.chronological.includes(:rich_text_notes)
end

# create's else branch didn't:
else
  respond_to do |format|
    format.turbo_stream { ... }
    format.html { render :index, status: :unprocessable_entity }  # @symptom_logs is nil!
  end
end
```

### Fix

Set `@symptom_logs` in the failure branch before rendering:

```ruby
else
  @symptom_logs = Current.user.symptom_logs.chronological.includes(:rich_text_notes)
  respond_to do |format|
    format.turbo_stream { render turbo_stream: turbo_stream.replace("symptom_log_form", partial: "form", locals: { symptom_log: @symptom_log }), status: :unprocessable_entity }
    format.html { render :index, status: :unprocessable_entity }
  end
end
```

**Rule of thumb:** Whenever a `create` or `update` failure path calls `render :index` or `render :new`, check what instance variables that template needs and set them all.

---

## Issue 3: Redundant Enum + Presence Validators Cause Duplicate Errors

### Symptom

Submitting a blank form shows 4 errors for 2 fields:

```
4 errors prevented this entry from being saved:
  Symptom type is not included in the list
  Severity is not included in the list
  Symptom type can't be blank
  Severity can't be blank
```

### Root Cause

Rails `enum :field, hash, validate: true` already rejects blank/nil values (they are "not included in the list"). Adding `validates :field, presence: true` on the same field creates a second, independent validator that also rejects blank — producing two errors for one blank input.

```ruby
# This combination produces 2 errors per blank field:
enum :symptom_type, { wheezing: 0, ... }, validate: true
validates :symptom_type, presence: true  # redundant — validate: true covers this
```

### Fix

Remove the presence validators for enum fields:

```ruby
# Before
enum :symptom_type, { wheezing: 0, coughing: 1, shortness_of_breath: 2, chest_tightness: 3 }, validate: true
enum :severity, { mild: 0, moderate: 1, severe: 2 }, validate: true
validates :symptom_type, presence: true
validates :severity, presence: true
validates :recorded_at, presence: true

# After
enum :symptom_type, { wheezing: 0, coughing: 1, shortness_of_breath: 2, chest_tightness: 3 }, validate: true
enum :severity, { mild: 0, moderate: 1, severe: 2 }, validate: true
validates :recorded_at, presence: true
```

**Update tests** — after removing presence validators, the error message changes from `"can't be blank"` to `"is not included in the list"`. Tests asserting the exact message need updating:

```ruby
# Before
assert_includes log.errors[:symptom_type], "can't be blank"

# After (message-agnostic — resilient to future validator changes)
assert log.errors[:symptom_type].any?
```

---

## Prevention

### For Turbo Stream forms

- Never add HTML `required: true` to inputs when Rails model validations are the source of truth and Turbo Stream error responses are expected.
- Test the Turbo Stream error path explicitly — submit an invalid form via the browser and verify inline errors appear (not browser tooltips).

### For controller failure paths

- When a `create`/`update` failure calls `render :action`, immediately ask: what instance variables does that template need? Set them all.
- Consider extracting shared setup into a private method called from both `index` and the `create` failure branch:

  ```ruby
  before_action :set_symptom_logs, only: [:index, :create]

  private

  def set_symptom_logs
    @symptom_logs = Current.user.symptom_logs.chronological.includes(:rich_text_notes)
  end
  ```

### For enum validations

- `enum :field, hash, validate: true` is sufficient — do not add `validates :field, presence: true` for the same field.
- Write a test asserting exactly 1 error per blank enum field to catch regressions:

  ```ruby
  test "blank symptom_type produces exactly one error" do
    log = SymptomLog.new(valid_attributes.except(:symptom_type))
    assert_not log.valid?
    assert_equal 1, log.errors[:symptom_type].count
  end
  ```

---

## Related

- [Rails Active Record Validations — enum](https://guides.rubyonrails.org/active_record_validations.html)
- [Hotwire Turbo — Form Submissions](https://turbo.hotwired.dev/reference/streams)
- [Rails Layouts and Rendering — render](https://guides.rubyonrails.org/layouts_and_rendering.html#using-render)
