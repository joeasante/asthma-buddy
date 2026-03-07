---
status: pending
priority: p2
issue_id: "051"
tags: [code-review, security, authentication, forms]
dependencies: []
---

# Registration Form Missing `maxlength: 72` on Password Fields — Silent bcrypt Truncation

## Problem Statement

bcrypt silently truncates passwords at 72 bytes. The login form (`sessions/new.html.erb`) correctly sets `maxlength: 72` on the password field, but the registration form (`registrations/new.html.erb`) does not. A user who sets a password longer than 72 characters at registration will have their effective password silently truncated, creating a mismatch between what they typed and what actually authenticates them.

## Findings

**Flagged by:** security-sentinel (MEDIUM-03)

**Login form (correct):** `app/views/sessions/new.html.erb:17`
```erb
<%= form.password_field :password, required: true, autocomplete: "current-password", maxlength: 72 %>
```

**Registration form (missing maxlength):** `app/views/registrations/new.html.erb:24`
```erb
<%= form.password_field :password, required: true, autocomplete: "new-password" %>
```

Also missing on the `password_confirmation` field and on `app/views/passwords/edit.html.erb`.

**Secondary:** The User model has no `length: { maximum: 72 }` validation, so there's no server-side signal about the truncation either.

## Proposed Solutions

### Solution A: Add maxlength to all password form fields (Recommended)

In `app/views/registrations/new.html.erb`:
```erb
<%= form.password_field :password, required: true, autocomplete: "new-password", maxlength: 72 %>
<%= form.password_field :password_confirmation, required: true, autocomplete: "new-password", maxlength: 72 %>
```

In `app/views/passwords/edit.html.erb`:
```erb
<%= form.password_field :password, required: true, autocomplete: "new-password", maxlength: 72 %>
<%= form.password_field :password_confirmation, required: true, autocomplete: "new-password", maxlength: 72 %>
```

- **Effort:** Tiny
- **Risk:** None

### Solution B: Add model validation + maxlength

```ruby
# app/models/user.rb
validates :password, length: { minimum: 8, maximum: 72 }, if: -> { password.present? || new_record? }
```

Plus fix the form fields (Solution A). The model validation surfaces a clear error rather than silent truncation.
- **Effort:** Small
- **Risk:** Low

## Acceptance Criteria

- [ ] Registration form password fields have `maxlength: 72`
- [ ] Password reset form fields have `maxlength: 72`
- [ ] User model validates password max length at 72 (optional but recommended)
- [ ] A user cannot set a password >72 characters that authenticates with the full string

## Work Log

- 2026-03-07: Created from security audit. security-sentinel MEDIUM-03.
