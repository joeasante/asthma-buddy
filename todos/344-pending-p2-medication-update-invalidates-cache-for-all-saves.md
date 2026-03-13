---
status: pending
priority: p2
issue_id: "344"
tags: [code-review, caching, performance, rails]
dependencies: []
---

# Medication on:update callback invalidates dashboard cache for all saves including irrelevant fields

## Problem Statement

`Medication` registers `after_commit -> { invalidate_dashboard_cache }, on: :update` unconditionally. Every save to a Medication record — including changes to `refilled_at`, `notes`, course dates, `sick_day_dose_puffs` that aren't displayed on the dashboard — triggers a cache invalidation.

The dashboard vars cache stores only: `id`, `name`, `standard_dose_puffs`, `sick_day_dose_puffs` (preventer and reliever). A change to `refilled_at` (refill timestamp) or course date fields doesn't affect any cached data but still busts the 5-minute cache.

For comparison, `Notification` already uses a guard: `after_commit -> { invalidate_badge_cache }, on: :update, if: :saved_change_to_read?`.

## Findings

- `app/models/medication.rb:36` — `after_commit -> { invalidate_dashboard_cache }, on: :update` — no guard condition
- Fields stored in the dashboard cache: `name`, `standard_dose_puffs`, `sick_day_dose_puffs`
- Fields that trigger unnecessary invalidation: `refilled_at`, `course`, `starts_on`, `ends_on`, `starting_dose_count`

## Proposed Solutions

### Option A: Guard with relevant column changes
```ruby
after_commit -> { invalidate_dashboard_cache }, on: :update,
  if: -> { saved_change_to_name? || saved_change_to_standard_dose_puffs? || saved_change_to_sick_day_dose_puffs? || saved_change_to_medication_type? || saved_change_to_course? }
```
- **Pros:** Cache only invalidated when displayed data actually changes
- **Cons:** Guard must be kept in sync as cached fields evolve
- **Effort:** Small
- **Risk:** Low (conservative: better to over-invalidate than under-invalidate)

### Option B: Accept unconditional invalidation
With a 5-minute TTL, spurious invalidations are minor — the cache repopulates within 5 minutes.
- **Pros:** No code change, no risk of missing a guard
- **Cons:** Unnecessary cache misses on refill operations
- **Effort:** None

## Recommended Action

Option A. The guard pattern is already established by `Notification`. Refill operations happen frequently and currently always bust the dashboard cache even though the displayed medication data hasn't changed.

## Technical Details

**Affected files:**
- `app/models/medication.rb`

## Acceptance Criteria

- [ ] `on: :update` callback guarded with `if:` condition covering display-relevant fields
- [ ] Refill (`refilled_at` change) does NOT invalidate dashboard cache
- [ ] Name/dose change DOES invalidate dashboard cache
- [ ] Tests updated to verify guard behaviour

## Work Log

- 2026-03-13: Identified in Phase 22 code review (performance-oracle)
