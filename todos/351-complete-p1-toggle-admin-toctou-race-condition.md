---
status: complete
priority: p1
issue_id: 351
tags: [code-review, security, admin]
dependencies: []
---

## Problem Statement

In `Admin::UsersController#toggle_admin`, the check `User.where(admin: true).count == 1 && user.admin?` and the subsequent `user.update!(admin: new_state)` are not atomic. Two concurrent requests could both pass the guard and leave zero admins.

## Findings

- `app/controllers/admin/users_controller.rb` — `toggle_admin` action performs a non-atomic check-then-act sequence
- The count check and the update are separate operations with no transaction or locking
- Under concurrent requests, both could read count == 2 (or > 1) and both proceed to remove admin, resulting in zero admins

## Proposed Solutions

A) **Wrap check and update in `User.transaction` block with pessimistic locking**
   - Pros: SQLite serializes writes, so a transaction alone is sufficient to prevent the race
   - Cons: Slightly more complex code

B) **Use a database CHECK constraint that prevents the last admin from being removed**
   - Pros: Database-level guarantee, impossible to bypass
   - Cons: CHECK constraints with subqueries are not supported in SQLite; would need a trigger instead

C) **Use `UPDATE ... WHERE` pattern for atomic check-and-update**
   - Pros: Single atomic SQL statement, no race possible
   - Cons: Harder to provide meaningful error messages on failure

## Recommended Action



## Technical Details

**Affected files:**
- app/controllers/admin/users_controller.rb

## Acceptance Criteria

- [ ] The count check and admin update are wrapped in a transaction
- [ ] Concurrent toggle_admin requests cannot result in zero admins
- [ ] Tests verify last-admin protection under concurrent conditions
