---
status: complete
priority: p1
issue_id: 350
tags: [code-review, performance, admin]
dependencies: []
---

## Problem Statement

`Admin::UsersController#index` uses `@users = User.order(created_at: :desc)` which loads every user into memory. The view calls `@users.size` forcing full materialization. This is a memory/performance issue that worsens with user growth and can be a DoS vector.

## Findings

- `app/controllers/admin/users_controller.rb` — `@users = User.order(created_at: :desc)` loads all users
- `app/views/admin/users/index.html.erb` — `@users.size` forces full collection materialization instead of using a COUNT query

## Proposed Solutions

A) **Add Pagy gem for pagination with `.page(params[:page]).per(50)`**
   - Pros: Clean, standard Rails pagination approach, well-maintained gem
   - Cons: Adds a dependency

B) **Add simple `.limit(100)` as a safety valve**
   - Pros: Quick fix, no new dependencies
   - Cons: Users beyond the limit are invisible, not a real solution

C) **Use offset/limit manual pagination without a gem**
   - Pros: No new dependency
   - Cons: More code to write and maintain, easy to get wrong

## Recommended Action



## Technical Details

**Affected files:**
- app/controllers/admin/users_controller.rb
- app/views/admin/users/index.html.erb

## Acceptance Criteria

- [ ] Admin users page paginates results (max 50 per page)
- [ ] Total user count uses `User.count` not `@users.size`
- [ ] Page loads remain fast even with 10,000+ users
