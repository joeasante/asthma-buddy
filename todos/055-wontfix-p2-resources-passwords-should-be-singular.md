---
status: pending
priority: p2
issue_id: "055"
tags: [code-review, routes, rails-conventions]
dependencies: []
---

# `resources :passwords` Should Be `resource :password` — Rails Naming Convention Violation

## Problem Statement

`config/routes.rb` uses `resources :passwords, param: :token` (plural), which implies a collection of independently addressable records and generates an unused `index` route (`GET /passwords`). Passwords are not a collection — a user has one password. The correct Rails idiom is `resource :password` (singular), which also supports `param: :token`.

## Findings

**Flagged by:** architecture-strategist (P2)

**Location:** `config/routes.rb:6`

```ruby
resources :passwords, param: :token  # plural — generates unused GET /passwords index
```

`resource :password, param: :token` generates the same named helpers (`new_password_path`, `edit_password_path(:token)`, `password_path(:token)`) without the unused `index` route and with correct URL semantics (`/password/TOKEN` vs `/passwords/TOKEN`).

## Proposed Solutions

### Solution A: Change to singular resource (Recommended)

```ruby
# config/routes.rb
resource :password, param: :token
```

Generated routes:
- `GET  /password/new` → `passwords#new`
- `GET  /password/:token/edit` → `passwords#edit`
- `PATCH /password/:token` → `passwords#update`
- `PUT  /password/:token` → `passwords#update`

Named helpers are identical to the current plural form. No controller changes required.

- **Effort:** Tiny (1-word change)
- **Risk:** Low — run `bin/rails routes` to verify helpers are unchanged

## Acceptance Criteria

- [ ] `config/routes.rb` uses `resource :password, param: :token`
- [ ] No `GET /passwords` route exists in `bin/rails routes`
- [ ] All existing route helpers (`new_password_path`, `edit_password_path`, `password_path`) still work
- [ ] All existing tests still pass

## Work Log

- 2026-03-07: Created from architecture review. architecture-strategist P2.
