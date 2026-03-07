---
status: pending
priority: p3
issue_id: "059"
tags: [code-review, testing, style, conventions]
dependencies: []
---

# `PasswordsControllerTest` Mixes `put` and `patch` for the Update Action

## Problem Statement

The HTML test for password update uses `put`, while the JSON test uses `patch`. Both route to `PasswordsController#update`, but mixing HTTP verbs within the same controller's test suite obscures the intended HTTP contract. The Rails convention since Rails 4 is `PATCH` for partial updates.

## Findings

**Flagged by:** pattern-recognition-specialist

**Location:** `test/controllers/passwords_controller_test.rb`

```ruby
# Line 45 — HTML: uses PUT
put password_path(@user.password_reset_token), params: { password: "newpassword123", ... }

# Line 79 — JSON: uses PATCH
patch password_path(@user.password_reset_token), params: { ... }, as: :json
```

Both work because `resources :passwords` (or `resource :password`) maps both PUT and PATCH to `update`. But consistency improves readability.

## Proposed Solution

Change line 45 from `put` to `patch`:

```ruby
patch password_path(@user.password_reset_token), params: { password: "newpassword123", ... }
```

- **Effort:** Tiny (1 word change)
- **Risk:** None

## Acceptance Criteria

- [ ] All `PasswordsControllerTest` update action tests use `patch`
- [ ] Tests pass

## Work Log

- 2026-03-07: Created from pattern review. pattern-recognition-specialist.
