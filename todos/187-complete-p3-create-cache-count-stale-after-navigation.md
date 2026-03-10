---
status: pending
priority: p3
issue_id: "187"
tags: [code-review, performance, caching, peak-flow]
dependencies: []
---

# Period Count Cache May Show Stale Value After Create + Immediate Index Navigation

## Problem Statement
PeakFlowReadingsController#index caches the period count with a 1-minute TTL. Since create now only shows a toast (no longer streams a row into the index), the user must navigate back to the index to see their new reading. If they do this within 1 minute, the list will show the new reading card (the list query is live) but `@period_count` in the stat strip will be one behind (cache miss won't occur for up to 1 minute). The reading appears in the list but the count doesn't match.

## Proposed Solutions

### Option A
Add a `touch` or explicit cache invalidation on `PeakFlowReading.after_save` / `after_destroy` to bust the count cache key for the user. Since the cache key includes preset/date params (unknown at create time), use a user-scoped version counter that increments on every save/destroy, making all count cache entries for that user stale.
- Effort: Medium
- Risk: Low

### Option B
Remove the cache entirely for period count — it's a simple COUNT query on an indexed column and is fast enough without caching. Keep caching only for more expensive aggregates.
- Effort: Small
- Risk: None

## Recommended Action

## Technical Details
- Affected files: app/controllers/peak_flow_readings_controller.rb, app/models/peak_flow_reading.rb

## Acceptance Criteria
- [ ] After creating a reading and navigating to the index within 1 minute, the period count in the stat strip matches the number of visible reading cards
- [ ] If Option A: a version counter or explicit cache key expiry is in place and covered by a test
- [ ] If Option B: the cache call for period count is removed from the controller

## Work Log
- 2026-03-10: Created via code review
