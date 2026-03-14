---
status: pending
priority: p1
issue_id: "376"
tags: [code-review, security, rails]
dependencies: []
---

## Problem Statement
The last-admin protection moved from a transacted controller check to `UserPolicy#toggle_admin?` which checks `User.admin.count > 1` OUTSIDE a transaction. Two admins demoting each other simultaneously could both pass the check and leave zero admins — complete admin lockout requiring DB intervention. This is a known pattern from docs/solutions/ (PR #17 review documented this exact issue).

## Findings
The TOCTOU (time-of-check-time-of-use) race condition exists because Pundit policy checks run before the controller action body, with no transactional wrapper. `UserPolicy#toggle_admin?` calls `User.admin.count > 1` in a separate read, then the controller proceeds to demote. A concurrent request can interleave between the check and the update, allowing both demotions to succeed and leaving zero admin users.

## Proposed Solutions
### Option A: Wrap toggle_admin in a transaction with row-level lock and re-check inside
- Pros: proven pattern (was used before), robust
- Cons: slightly more complex controller
- Effort: Small
- Risk: Low

### Option B: Add a database CHECK constraint or validation preventing zero admins
- Pros: database-level safety
- Cons: harder to implement in SQLite, error messaging is generic
- Effort: Medium
- Risk: Medium

## Acceptance Criteria
- [ ] Transaction wraps authorize + update in toggle_admin action
- [ ] `User.where(role: :admin).lock.count` checked inside transaction
- [ ] Test for concurrent demotion scenario verifies at least one admin remains
