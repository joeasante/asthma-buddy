---
status: pending
priority: p3
issue_id: "057"
tags: [code-review, style, rubocop]
dependencies: []
---

# `EmailVerificationsController` Uses `[ :show ]` Instead of `%i[ show ]`

## Problem Statement

Every controller uses `%i[ ]` for symbol arrays in `allow_unauthenticated_access`, except `EmailVerificationsController` which uses `[ :show ]`. RuboCop with `rubocop-rails-omakase` enforces `%i[ ]` as the preferred syntax.

## Findings

**Flagged by:** pattern-recognition-specialist

**Location:** `app/controllers/email_verifications_controller.rb:4`

```ruby
allow_unauthenticated_access only: [ :show ]   # ← inconsistent syntax
```

All others:
```ruby
allow_unauthenticated_access only: %i[ new create ]  # sessions_controller.rb
allow_unauthenticated_access only: %i[ new create ]  # registrations_controller.rb
allow_unauthenticated_access only: %i[ index ]       # home_controller.rb
```

## Proposed Solution

```ruby
allow_unauthenticated_access only: %i[ show ]
```

One character change. `bin/rubocop` will confirm.

## Acceptance Criteria

- [ ] `app/controllers/email_verifications_controller.rb` uses `%i[ show ]`
- [ ] `bin/rubocop` passes with no style violations

## Work Log

- 2026-03-07: Created from pattern review. pattern-recognition-specialist.
