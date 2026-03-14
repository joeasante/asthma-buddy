---
status: pending
priority: p3
issue_id: "392"
tags: [code-review, database, performance]
dependencies: []
---

## Problem Statement
The index on `users.role` has only 2 values (member/admin). With most users being members, the index provides minimal read benefit while adding write overhead on every user insert/update. The only query using it is `User.admin.count`, which is rare and admin-only.

## Findings
The `users.role` column index was identified as low-cardinality (2 distinct values). For a small users table, a sequential scan is likely faster than an index lookup for the minority value (admin), and the index adds write overhead for every user mutation.

## Proposed Solutions
### Option A: Remove the index
Drop the index on `users.role`. The `User.admin.count` query on a small table is fast without it. Effort: Small.

### Option B: Keep for future use
Retain the index in case more roles or role-based queries are added later. Effort: None.

## Acceptance Criteria
- [ ] If removed, `User.admin.count` still works correctly
- [ ] Write performance marginally improves (no index maintenance on user writes)
- [ ] All tests pass
