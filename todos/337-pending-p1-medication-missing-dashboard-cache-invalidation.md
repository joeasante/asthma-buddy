---
status: pending
priority: p1
issue_id: "337"
tags: [code-review, caching, rails, correctness]
dependencies: []
---

# Medication model missing dashboard cache invalidation callbacks

## Problem Statement

`Medication` has no `after_commit` callbacks to invalidate the `dashboard_vars` cache. The dashboard caches `preventer_adherence` (an array of Medication objects) and `reliever_medications` (another array of Medication objects) under `"dashboard_vars/#{user_id}/#{Date.current}"` with a 5-minute TTL.

Any write to `Medication` — adding a new one, editing `doses_per_day`, renaming, changing `medication_type`, performing a refill (`starting_dose_count` + `refilled_at`), or destroying — will not invalidate this cache. The dashboard will display stale adherence data and stale reliever medication info for up to 5 minutes after the mutation.

The `DoseLog` and `HealthEvent` models both have `after_commit` callbacks for this purpose. `Medication` is the one uncovered write path.

Flagged by: kieran-rails-reviewer, architecture-strategist, agent-native-reviewer (all in Phase 22 code review).

## Findings

- `app/models/medication.rb` — no `after_commit` callback that calls `invalidate_dashboard_cache`
- `app/controllers/settings/medications_controller.rb` — `#update`, `#refill`, `#destroy` all mutate Medication with no cache invalidation
- `app/controllers/concerns/dashboard_variables.rb:16` — caches `preventer_adherence` and `reliever_medications` (both Medication queries) under `dashboard_vars/#{user_id}/#{Date.current}`
- `app/models/dose_log.rb:16-17` — reference implementation: `after_commit -> { invalidate_dashboard_cache }, on: :create/destroy`
- `app/models/health_event.rb:45-47` — reference implementation: all three lifecycle events covered

## Proposed Solutions

### Option A: Add full lifecycle callbacks to Medication (Recommended)
```ruby
# app/models/medication.rb
after_commit -> { invalidate_dashboard_cache }, on: :create
after_commit -> { invalidate_dashboard_cache }, on: :update
after_commit -> { invalidate_dashboard_cache }, on: :destroy

private

  def invalidate_dashboard_cache
    Rails.cache.delete("dashboard_vars/#{user_id}/#{Date.current}")
  end
```
Add `MedicationDashboardCacheTest` top-level class in `test/models/medication_test.rb` with `use_transactional_tests = false`, covering create, update, and destroy paths.
- **Pros:** Complete coverage, matches DoseLog/HealthEvent pattern exactly
- **Cons:** Fires on every Medication update including fields unrelated to the dashboard (e.g. `sick_day_dose_puffs`)
- **Effort:** Small
- **Risk:** Low

### Option B: Narrow to dashboard-relevant field changes only
Guard the update callback: `if: -> { saved_change_to_medication_type? || saved_change_to_doses_per_day? || saved_change_to_starting_dose_count? || saved_change_to_refilled_at? || saved_change_to_course? }`
- **Pros:** No unnecessary cache evictions
- **Cons:** More fragile — future dashboard columns require updating the guard
- **Effort:** Small
- **Risk:** Low (but higher than Option A due to guard maintenance)

## Recommended Action

Option A. The additional cache evictions from Option A are cheap (a single `Rails.cache.delete` call), and the guard in Option B is a maintenance trap every time the dashboard query changes.

## Technical Details

**Affected files:**
- `app/models/medication.rb` — add callbacks + private method
- `test/models/medication_test.rb` — add `MedicationDashboardCacheTest` top-level class

**Cache key:** `"dashboard_vars/#{user_id}/#{Date.current}"` (must match exactly what `DashboardVariables` writes)

## Acceptance Criteria

- [ ] `Medication` has `after_commit` callbacks for create, update, and destroy
- [ ] The `invalidate_dashboard_cache` private method follows the same pattern as `DoseLog` and `HealthEvent`
- [ ] `MedicationDashboardCacheTest` exists as a top-level class with `use_transactional_tests = false`
- [ ] Tests cover: create invalidates cache, update invalidates cache, destroy invalidates cache
- [ ] Full test suite passes (516+ tests, 0 failures)

## Work Log

- 2026-03-13: Identified in Phase 22 code review (kieran-rails-reviewer, architecture-strategist, agent-native-reviewer)
