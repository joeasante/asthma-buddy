---
status: complete
priority: p3
issue_id: "396"
tags: [code-review, quality, simplification]
dependencies: []
---

## Problem Statement
`Admin::UsersController#toggle_admin` has 3 layers checking the same "last admin" constraint: (1) pre-transaction `User.where(role: :admin).count <= 1` guard, (2) inside-transaction `User.where(role: :admin).lock.count <= 1` with `FOR UPDATE` lock, and (3) Pundit policy. The pre-transaction check is redundant — the locked check inside the transaction is the authoritative one, and the pre-check adds a query without preventing any race.

## Proposed Solutions
### Option A: Remove pre-transaction guard
Remove the outer `if` check and rely on the locked check inside the transaction block. Fewer queries, no behavior change.

**Effort:** Small.

### Option B: Keep for UX (fast fail)
The pre-transaction check avoids acquiring a lock in the common case. Keep it as an optimization.

**Effort:** None.

## Acceptance Criteria
- [ ] Toggle admin still prevents demoting last admin
- [ ] All tests pass
