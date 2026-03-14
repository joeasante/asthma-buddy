---
status: complete
priority: p2
issue_id: 361
tags: [code-review, performance, admin]
dependencies: []
---

## Problem Statement

The admin dashboard fires 8 queries that could be consolidated. 6 separate COUNT queries and 2 ORDER/LIMIT queries all hit the same `users` table.

## Findings

In `app/controllers/admin/dashboard_controller.rb`, the index action runs:
- 6 separate COUNT queries against the `users` table (total users, admins, verified, unverified, recent signups, etc.)
- 2 ORDER/LIMIT queries for recent and active users

All 6 COUNT queries could be consolidated into a single SQL query using conditional aggregation (e.g., `COUNT(CASE WHEN admin = true THEN 1 END)`), reducing database round-trips from 8 to 3.

## Proposed Solutions

**A) Single SQL query with conditional aggregation using `pick(Arel.sql(...))`**
- Pros: 6 queries reduced to 1; significant reduction in database round-trips; straightforward SQL
- Cons: Raw SQL is less readable than ActiveRecord; must be careful with Arel.sql injection safety

**B) Cache the stats with a short TTL**
- Pros: Avoids query consolidation complexity; simple implementation
- Cons: Stale data; still runs all 8 queries on cache miss; adds caching complexity

## Recommended Action



## Technical Details

**Affected files:**
- `app/controllers/admin/dashboard_controller.rb`

## Acceptance Criteria

- [ ] Admin dashboard makes at most 3 queries (1 consolidated count + 2 ORDER/LIMIT)
- [ ] Page load time stays under 200ms
