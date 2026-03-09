---
status: pending
priority: p2
issue_id: "120"
tags: [code-review, rails, views, quality, profiles, errors]
dependencies: []
---

# Error filtering by string match on attribute name — `:base` errors bleed into personal details form

## Problem Statement

The profile page has multiple forms. Errors are routed to each form by checking if the attribute name contains "password" (`e.attribute.to_s.include?("password")`). This has a latent bug: the controller adds a `:base` error for wrong current password (`Current.user.errors.add(:base, "Current password is incorrect")`). `:base` does not contain "password", so `_personal_details_form.html.erb`'s condition `!user.errors.all? { |e| e.attribute.to_s.include?("password") }` will evaluate true for `:base` errors — meaning the personal details error box will show a password error message.

## Findings

- `app/views/profiles/_personal_details_form.html.erb:2` — `!user.errors.all? { |e| e.attribute.to_s.include?("password") }`
- `app/views/profiles/_password_form.html.erb:2` — `user.errors.any? { |e| e.attribute.to_s.include?("password") || e.attribute == :base }`
- `app/controllers/profiles_controller.rb:24` — `Current.user.errors.add(:base, "Current password is incorrect")`
- Bug: password auth failure shows the "Current password is incorrect" error in the personal details section

## Proposed Solutions

### Option A: Use a specific attribute name (Recommended)
In the controller, add the error to `:current_password` instead of `:base`:
```ruby
Current.user.errors.add(:current_password, "is incorrect")
```
Then the string match `include?("password")` correctly catches it in the password form, not the personal details form.

**Effort:** Small | **Risk:** Low

### Option B: Controller-level flash or instance variable
Set `@password_error = true` in the controller when auth fails. Each partial checks its own flag.
**Effort:** Small | **Risk:** Low

## Recommended Action

Option A — simplest fix, no structural change to the forms.

## Technical Details

- **Affected files:** `app/controllers/profiles_controller.rb`, `app/views/profiles/_personal_details_form.html.erb`, `app/views/profiles/_password_form.html.erb`

## Acceptance Criteria

- [ ] Wrong current password error appears only in the password form, not personal details
- [ ] Validation errors for `full_name`/`email_address` appear only in personal details form
- [ ] Test covers this error routing

## Work Log

- 2026-03-08: Identified by pattern-recognition-specialist during PR review
