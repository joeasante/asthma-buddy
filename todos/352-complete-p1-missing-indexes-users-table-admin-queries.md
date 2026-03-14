---
status: complete
priority: p1
issue_id: 352
tags: [code-review, performance, database]
dependencies: []
---

## Problem Statement

The admin dashboard queries `users.created_at`, `users.last_sign_in_at`, and `users.sign_in_count` columns but none have indexes. All 6+ COUNT queries in the admin dashboard perform full table scans.

## Findings

- `db/schema.rb` — no indexes defined on `users.created_at`, `users.last_sign_in_at`, or `users.sign_in_count`
- `app/controllers/admin/dashboard_controller.rb` — multiple COUNT queries filter on these columns without index support

## Proposed Solutions

A) **Add a migration with indexes on all three columns**
   - Pros: Covers all current query patterns, straightforward
   - Cons: Three additional indexes add slight write overhead

B) **Add only `created_at` and `last_sign_in_at` indexes (sign_in_count is low cardinality, less useful)**
   - Pros: Fewer indexes, lower write overhead
   - Cons: Queries filtering on sign_in_count still perform full scans

## Recommended Action



## Technical Details

**Affected files:**
- db/schema.rb
- app/controllers/admin/dashboard_controller.rb

## Acceptance Criteria

- [ ] Index exists on users.created_at
- [ ] Index exists on users.last_sign_in_at
- [ ] Admin dashboard loads efficiently with 10,000+ users
