---
status: complete
priority: p1
issue_id: "322"
tags: [code-review, correctness, medications, dose-logs, n-plus-one]
dependencies: []
---

# `remaining_doses` Sums All Historical Dose Logs, Ignoring `refilled_at`

## Problem Statement

`app/models/medication.rb` computes `remaining_doses` by subtracting the total puffs used from the total doses in a pack. However, `dose_logs.sum(:puffs)` sums **all** dose logs ever recorded for the medication — including logs from before the most recent refill. After a refill, the count should reset to count only puffs taken since `refilled_at`. As implemented, `remaining_doses` goes negative after a refill and then slowly climbs back toward the correct value as more logs accumulate. This makes the "remaining doses" display in the Medications UI actively misleading.

Additionally, when `dose_logs` is already loaded in memory (e.g. via `includes(:dose_logs)`), `dose_logs.sum(:puffs)` fires an additional SQL query instead of using the in-memory collection — a hidden N+1.

## Findings

**Flagged by:** performance-oracle, kieran-rails-reviewer

```ruby
# app/models/medication.rb (~line 56)
def remaining_doses
  total_doses - dose_logs.sum(:puffs)  # BUG: sums ALL historical logs
end
```

Correct semantics: only sum puffs taken since the last refill:
```ruby
def remaining_doses
  since = refilled_at || created_at
  taken = if dose_logs.loaded?
    dose_logs.select { |dl| dl.created_at >= since }.sum(&:puffs)
  else
    dose_logs.where("created_at >= ?", since).sum(:puffs)
  end
  total_doses - taken
end
```

The `loaded?` guard eliminates the N+1 when the association is eager-loaded.

## Proposed Solutions

### Option A: Scope to `refilled_at` with `loaded?` guard (Recommended)
As shown above — filter by `refilled_at || created_at` and respect the loaded state.

**Pros:** Correct semantics, no N+1, minimal change
**Cons:** Requires a migration or assumption that `created_at` is a valid baseline for pre-refill medications
**Effort:** Small
**Risk:** Low — logic change only, no schema change needed

### Option B: Store a `doses_at_refill` snapshot
On refill, snapshot `dose_logs.sum(:puffs)` into a `doses_used_before_refill` column. `remaining_doses` subtracts `total_doses - (dose_logs.sum(:puffs) - doses_used_before_refill)`.

**Pros:** Handles edge cases around exactly when refill happens
**Cons:** Requires schema migration; more complex
**Effort:** Medium
**Risk:** Medium

### Recommended Action

Option A. Use `refilled_at || created_at` as the baseline. This matches user mental model: "doses remaining since last refill (or since creation if never refilled)."

## Technical Details

- **File:** `app/models/medication.rb`, `remaining_doses` method (~line 56)
- `refilled_at` column already exists (set by `refill` action in `Settings::MedicationsController`)
- `dose_logs` association: `has_many :dose_logs`

## Acceptance Criteria

- [ ] `remaining_doses` only counts puffs taken since `refilled_at` (or `created_at` if never refilled)
- [ ] After a refill, `remaining_doses` resets to `total_doses`
- [ ] When `dose_logs` is loaded, no additional SQL query is fired
- [ ] Unit tests cover: no refill, single refill, multiple refills
- [ ] Existing medication tests pass

## Work Log

- 2026-03-12: Created from Milestone 2 code review — performance-oracle + kieran-rails-reviewer finding
