---
status: pending
priority: p2
issue_id: "115"
tags: [code-review, rails, quality, profiles, dry]
dependencies: []
---

# Instance variable setup duplicated 3× in `ProfilesController` — extract a `before_action`

## Problem Statement

Two instance variables are set in three separate places in `ProfilesController`: in `show`, in the password-auth-failure branch of `update`, and in the validation-failure branch of `update`. Any change to show-page initialisation must be made in three places. The codebase pattern is to use `before_action` for shared ivar setup.

## Findings

- `app/controllers/profiles_controller.rb:7-8` — in `show`
- `app/controllers/profiles_controller.rb:25-26` — in `update` password auth failure branch
- `app/controllers/profiles_controller.rb:34-35` — in `update` validation failure branch
- Reference: `SymptomLogsController` uses `before_action :set_symptom_log`; `PeakFlowReadingsController` uses `before_action :set_has_personal_best`

## Proposed Solutions

### Option A: Extract `set_profile_data` before_action (Recommended)
```ruby
before_action :set_profile_data, only: %i[show update]

private

def set_profile_data
  @current_personal_best = PersonalBestRecord.current_for(Current.user)
  @personal_best_record  = Current.user.personal_best_records.new(recorded_at: Time.current)
end
```
Remove the inline assignments from `show` and both `update` failure branches.

**Effort:** Small | **Risk:** Low

## Recommended Action

Option A.

## Technical Details

- **Affected file:** `app/controllers/profiles_controller.rb`

## Acceptance Criteria

- [ ] `set_profile_data` private method extracted
- [ ] Called via `before_action` for `show` and `update`
- [ ] No duplicate ivar assignments remaining in controller body

## Work Log

- 2026-03-08: Identified by pattern-recognition-specialist and kieran-rails-reviewer
