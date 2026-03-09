---
status: pending
priority: p2
issue_id: "137"
tags: [code-review, performance, personal-best]
dependencies: ["127"]
---

# `after_save` on PersonalBestRecord Fires on Every Save

## Problem Statement

`PersonalBestRecord` has `after_save :recompute_nil_zone_readings` with no guard condition. Any save to a `PersonalBestRecord` — even updating a future unrelated attribute — triggers the full zone recomputation loop. This is wasteful and will grow more expensive as the peak flow readings table grows.

Note: todo #127 (N+1 UPDATE loop) should be fixed first; this todo adds the conditional guard.

Flagged by: performance-oracle, architecture-strategist.

## Findings

**File:** `app/models/personal_best_record.rb`

```ruby
after_save :recompute_nil_zone_readings
```

No condition. Fires on every save including: updating `updated_at`, touching the record, or changing any future column.

## Proposed Solution

Add a guard condition:

```ruby
after_save :recompute_nil_zone_readings, if: -> { saved_change_to_value? || previously_new_record? }
```

`saved_change_to_value?` is `true` only when the `value` attribute actually changed in this save. `previously_new_record?` is `true` on the first save (create). This ensures the recomputation runs when it matters and is skipped otherwise.

## Acceptance Criteria

- [ ] `after_save` guard added with `saved_change_to_value? || previously_new_record?`
- [ ] Touching a `PersonalBestRecord` (no value change) does NOT trigger `recompute_nil_zone_readings`
- [ ] Creating a new `PersonalBestRecord` still triggers recomputation
- [ ] Updating `value` still triggers recomputation
- [ ] Add a test asserting no zone recomputation when a non-value attribute changes

## Work Log

- 2026-03-08: Identified by performance-oracle and architecture-strategist
