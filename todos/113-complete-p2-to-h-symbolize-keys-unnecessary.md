---
status: pending
priority: p2
issue_id: "113"
tags: [code-review, rails, quality, profiles, strong-params]
dependencies: []
---

# `profile_params.to_h.symbolize_keys` — unnecessary conversion, drops permitted flag

## Problem Statement

`ProfilesController#update` converts strong params to a plain Hash before passing to ActiveRecord. `ActionController::Parameters` natively supports symbol key access and can be passed directly to `ActiveRecord#update`. The conversion is unnecessary, strips the `permitted?` tracking flag from the params object, and diverges from every other controller in the codebase.

## Findings

- `app/controllers/profiles_controller.rb:12` — `update_attrs = profile_params.to_h.symbolize_keys`
- `app/controllers/symptom_logs_controller.rb:43` — passes `symptom_log_params` directly to `.new()`
- `app/controllers/peak_flow_readings_controller.rb:82` — passes `peak_flow_reading_params` directly to `.new()`
- `ActionController::Parameters` supports `[]`, `key?`, `delete` with symbol keys — no conversion needed

## Proposed Solutions

### Option A: Use profile_params directly (Recommended)
```ruby
def update
  update_attrs = profile_params
  update_attrs.delete(:password) if update_attrs[:password].blank?
  update_attrs.delete(:password_confirmation) if update_attrs[:password].blank?
  # ... rest unchanged
end
```
Note: `ActionController::Parameters#delete` works fine.

**Effort:** Small | **Risk:** Low

## Recommended Action

Option A — remove `.to_h.symbolize_keys`.

## Technical Details

- **Affected file:** `app/controllers/profiles_controller.rb:12`

## Acceptance Criteria

- [ ] `profile_params` passed directly to `Current.user.update()` without `.to_h.symbolize_keys`
- [ ] All existing update flows (password, profile fields) still work correctly

## Work Log

- 2026-03-08: Identified by kieran-rails-reviewer, code-simplicity-reviewer, and pattern-recognition-specialist
