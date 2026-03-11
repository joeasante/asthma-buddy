---
status: pending
priority: p2
issue_id: "249"
tags: [code-review, security, data-integrity, rails, model]
dependencies: []
---

# `starts_on` / `ends_on` Not Nullified Server-Side When `course: false`

## Problem Statement

The Stimulus controller disables `starts_on` and `ends_on` form inputs when the course checkbox is unchecked — this is the only guard preventing those values from being submitted on non-course medications. A user with a REST client (curl, Burp Suite) can POST `course=0&starts_on=2024-01-01&ends_on=2024-01-02` and those date values will be persisted to a non-course medication silently. The model validations only enforce date ordering when `course?` is true. No model-level protection strips orphaned dates.

In a health record system, unexpected data in records is a data integrity concern regardless of immediate exploitability.

## Findings

`app/controllers/settings/medications_controller.rb` medication_params permits `:starts_on` and `:ends_on` unconditionally.

`app/models/medication.rb` validates dates only when `course?` is true — does not strip them when `course?` is false.

`app/javascript/controllers/course_toggle_controller.js` disables inputs client-side but this is browser-only; bypassed by direct HTTP calls.

Confirmed by: security-sentinel.

## Proposed Solutions

### Option A — `before_validation` callback on the model *(Recommended)*

```ruby
before_validation :clear_course_dates_unless_course

private

  def clear_course_dates_unless_course
    unless course?
      self.starts_on = nil
      self.ends_on   = nil
    end
  end
```

Pros: model is self-consistent regardless of caller (browser, API, console, test)
Cons: none — the callback has no side effects for legitimate non-course records

### Option B — Strip in the controller before saving

```ruby
def create
  medication_params_clean = medication_params
  unless medication_params_clean[:course] == "1"
    medication_params_clean = medication_params_clean.except(:starts_on, :ends_on)
  end
  ...
end
```

Pros: keeps model simple
Cons: must be applied to both create and update; controller-level fix can be forgotten on new actions; doesn't protect console/API creation

## Recommended Action

Option A — model callback. One method, protects all paths.

## Technical Details

- **Affected file:** `app/models/medication.rb`
- **Test to add:** `test "non-course medication created via direct params does not persist starts_on/ends_on"` in `test/models/medication_test.rb`

## Acceptance Criteria

- [ ] `Medication.create!(course: false, starts_on: Date.today, ends_on: 7.days.from_now.to_date, ...)` results in `starts_on: nil` and `ends_on: nil`
- [ ] `Medication.create!(course: true, starts_on: Date.today, ends_on: 7.days.from_now.to_date, ...)` still persists both dates correctly
- [ ] Test covering the strip behaviour is added to `test/models/medication_test.rb`
- [ ] No existing tests broken

## Work Log

- 2026-03-10: Found by security-sentinel during Phase 18 code review
