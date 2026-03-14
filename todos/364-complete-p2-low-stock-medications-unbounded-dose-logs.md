---
status: complete
priority: p2
issue_id: 364
tags: [code-review, performance, queries]
dependencies: []
---

## Problem Statement

Dashboard `@low_stock_medications` loads ALL dose_logs unbounded via `.includes(:dose_logs)`. For a user logging 2 doses/day for 2 years, that is ~1,460 records loaded into memory just to check remaining stock.

## Findings

In `app/controllers/dashboard_controller.rb` and `app/controllers/concerns/dashboard_variables.rb`, the low stock medications query uses `.includes(:dose_logs)` which eager-loads every dose log ever recorded for each medication. The only purpose is to calculate remaining doses (total doses minus logged doses), but this loads the entire history into memory.

For a user who has been logging doses for an extended period, this becomes increasingly expensive. At 2 doses/day for 2 years, approximately 1,460 ActiveRecord objects are instantiated per medication just to get a count.

## Proposed Solutions

**A) Scope eager load to dose logs since last refill**
- Pros: Only loads relevant records; directly addresses the unbounded query; minimal schema change
- Cons: Requires knowing the last refill date; slightly more complex query

**B) Add a counter cache or materialized column for remaining doses**
- Pros: Most efficient at read time; O(1) lookup; no eager loading needed
- Cons: Requires migration; must be maintained on dose log create/delete and refill events

**C) Accept for now, add TODO for when data grows**
- Pros: No immediate work
- Cons: Performance degrades linearly with time; technical debt accumulates

## Recommended Action



## Technical Details

**Affected files:**
- `app/controllers/dashboard_controller.rb`
- `app/controllers/concerns/dashboard_variables.rb`

## Acceptance Criteria

- [ ] Dose log eager loading is scoped to relevant time window
- [ ] Dashboard loads efficiently for users with years of data
