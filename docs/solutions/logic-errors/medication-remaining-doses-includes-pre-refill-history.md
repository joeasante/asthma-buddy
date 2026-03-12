---
title: "Medication remaining_doses sums all historical logs, going negative after refill"
problem_type: logic-error
component: "Medication model, dose tracking, refill logic"
tags: [medications, remaining-doses, refill, correctness, n-plus-one, loaded, dose-logs]
symptoms:
  - Remaining doses displayed as a large negative number immediately after a refill
  - Stock level shown in UI is misleading — never resets to the new pack count
  - Low-stock warnings may not clear after a refill
  - Hidden N+1 query when dose_logs association is eager-loaded (sum fires SQL even on loaded? association)
root_cause: "remaining_doses was computed as starting_dose_count - dose_logs.sum(:puffs), summing ALL historical logs for the medication. The refill action correctly resets starting_dose_count but dose_logs.sum(:puffs) still included all pre-refill puffs, producing a count that immediately went negative. Also: dose_logs.sum(:puffs) always fires SQL even when dose_logs is loaded in memory."
---

# `remaining_doses` Sums All Historical Dose Logs, Going Negative After Refill

## Problem

`Medication#remaining_doses` computed the remaining inhaler count using:

```ruby
def remaining_doses
  return nil if starting_dose_count.nil?
  starting_dose_count - dose_logs.sum(:puffs)  # sums ALL historical logs
end
```

The `refill` action resets `starting_dose_count` to the new pack size and records `refilled_at`:

```ruby
# Settings::MedicationsController#refill
@medication.update(starting_dose_count: new_count, refilled_at: Time.current)
```

But `dose_logs.sum(:puffs)` still summed **every puff ever logged** for the medication — including all the pre-refill history. Immediately after a refill of 200 doses, if the user had 150 historical puffs logged:

```
remaining_doses = 200 - 150 = 50   ← wrong! should be 200
```

And as the user continued logging, it would keep decreasing from 50, never starting fresh from 200.

### Secondary issue: N+1 on loaded association

`dose_logs.sum(:puffs)` always fires a SQL `SUM` query — even when `dose_logs` was already eager-loaded via `includes(:dose_logs)`. This produced an N+1 on every settings page (one extra query per medication).

## Root Cause

The original `remaining_doses` had a comment acknowledging the refill design:

```ruby
# NOTE: Phase 13 will introduce a refill action that resets starting_dose_count
# and records refilled_at. This method will then correctly reflect the
# post-refill count because starting_dose_count itself is updated on refill.
```

This comment assumed that resetting `starting_dose_count` would fix the mismatch — but it doesn't, because `dose_logs.sum(:puffs)` has no knowledge of when the refill happened. The sum always spans the full history.

## Solution

Scope the sum to only dose logs recorded **at or after** the last refill, with a `loaded?` guard:

```ruby
# Returns how many doses remain in the current inhaler.
# Only counts puffs taken since the last refill (or since creation if never refilled),
# so the count resets to starting_dose_count when a refill is recorded.
# Uses dose_logs.loaded? to avoid an extra query when the association is eager-loaded.
def remaining_doses
  return nil if starting_dose_count.nil?
  since = refilled_at || created_at
  taken = if dose_logs.loaded?
    dose_logs.select { |dl| dl.recorded_at >= since }.sum(&:puffs)
  else
    dose_logs.where("recorded_at >= ?", since).sum(:puffs)
  end
  starting_dose_count - taken
end
```

- `refilled_at || created_at` — uses the refill timestamp as the baseline; falls back to creation time for medications that have never been refilled
- `dose_logs.loaded?` — when the association is already in memory (e.g. loaded via `includes(:dose_logs)`), use `Enumerable#select` + `#sum` to avoid the extra SQL query

### Behaviour after fix

| Scenario | Before fix | After fix |
|---|---|---|
| No refill, 50 puffs used from 200 | 150 ✓ | 150 ✓ |
| After refill to 200, 0 new puffs | 50 ✗ | 200 ✓ |
| After refill to 200, 30 new puffs | 20 ✗ | 170 ✓ |

## Prevention

### Rule of thumb
When a model has an "event that resets a counter" (refill, restart, archive), every calculation that reads history must:

1. Identify the "since when?" timestamp for the current period (e.g. `refilled_at`)
2. Apply it as a filter to ALL historical queries — never sum unbounded history
3. Fall back to `created_at` when the reset event hasn't happened yet

### `loaded?` guard for `.sum()` on associations

When a method does `.sum()` on an `has_many` association and may be called in a context where the association is eager-loaded:

```ruby
# Without guard — always fires SQL (N+1 when called on a collection)
dose_logs.sum(:puffs)

# With guard — respects in-memory collection
if dose_logs.loaded?
  dose_logs.sum(&:puffs)
else
  dose_logs.sum(:puffs)
end
```

Apply this pattern to any method that may be called inside a `.map` or `.select` on a collection loaded with `includes`.

### Code review signals
- A model has a `refilled_at` / `reset_at` / `restarted_at` column — verify every aggregate calculation that spans history uses it as a filter
- A method calls `.sum(:col)` on an `has_many` association — check if the controller eager-loads it; if so, add a `loaded?` guard
- A comment like "Phase N will reset X — this will then work" — these are deferred correctness debts that often land wrong when Phase N arrives

### Test pattern

```ruby
test "remaining_doses only counts puffs since last refill" do
  med = Medication.create!(
    user: @user, name: "Test", medication_type: :preventer,
    standard_dose_puffs: 2, starting_dose_count: 200, doses_per_day: 2
  )
  DoseLog.create!(user: @user, medication: med, puffs: 50, recorded_at: 5.days.ago)

  # Refill to 200
  med.update!(starting_dose_count: 200, refilled_at: Time.current)

  # Log 30 puffs after refill
  DoseLog.create!(user: @user, medication: med, puffs: 30, recorded_at: 1.hour.ago)

  assert_equal 170, med.remaining_doses
end

test "remaining_doses with loaded? association avoids extra query" do
  med = Medication.includes(:dose_logs).find(@medication.id)
  assert med.dose_logs.loaded?
  assert_no_queries { med.remaining_doses }
end
```

## Related

- `app/models/medication.rb` — `remaining_doses`, `days_of_supply_remaining`, `low_stock?`
- `app/controllers/settings/medications_controller.rb` — `refill` action
- `app/controllers/settings/base_controller.rb` — `set_header_eyebrow_vars` (uses `includes(:dose_logs)` after this fix)
- Todo 322, 325 — the paired N+1 fix in the settings base controller
