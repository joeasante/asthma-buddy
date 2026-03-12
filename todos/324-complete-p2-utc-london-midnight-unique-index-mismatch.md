---
status: complete
priority: p2
issue_id: "324"
tags: [code-review, timezone, sqlite, peak-flow, correctness]
dependencies: []
---

# UTC vs London Timezone Mismatch in `one_session_per_day` Validation

## Problem Statement

The `one_session_per_day` uniqueness validation in `PeakFlowReading` (or `DoseLog`) uses Ruby's `beginning_of_day` which respects `Time.zone` (London/Europe). The corresponding SQLite unique index uses `DATE(recorded_at)` which operates in UTC. For London users during GMT+1 (British Summer Time, March–October), recordings made between midnight UTC and 1am London time will pass the Ruby validation (different London-date), hit the unique index (same UTC-date), and raise `ActiveRecord::RecordNotUnique` — an unhandled 500 rather than a clean validation error.

## Findings

**Flagged by:** kieran-rails-reviewer (rated HIGH)

- Ruby validation: `beginning_of_day` → London midnight (e.g. `2026-06-15 00:00:00 +0100`)
- SQLite index: `DATE(recorded_at)` → UTC date (e.g. `2026-06-14` for a 12:30am London recording)
- Mismatch window: 1 hour during BST (midnight–1am London time)
- Result: `ActiveRecord::RecordNotUnique` raised at the database layer, not caught by the model validation

## Proposed Solutions

### Option A: Normalise the Ruby validation to UTC (Recommended)
Change `beginning_of_day` in the validation to use `utc.beginning_of_day` to match the SQLite `DATE()` function:

```ruby
validates :recorded_at, uniqueness: {
  scope: :user_id,
  message: "only one reading per day",
  conditions: -> { where("DATE(recorded_at) = DATE(?)", recorded_at.utc) }
}
```

Or alternatively, update the SQLite index to use London time using `strftime` with an offset. This option aligns Ruby and SQL to the same domain (UTC).

**Pros:** Matches the index; eliminates the mismatch; no index change needed
**Cons:** "One reading per day" is now UTC-day, which may feel unintuitive for users
**Effort:** Small
**Risk:** Low

### Option B: Change SQLite index to London-offset `DATE()`
Drop and recreate the unique index using `DATE(recorded_at, '+1 hour')` (or with BST-aware offset). Ruby validation keeps `beginning_of_day`.

**Pros:** User-facing semantics match London timezone
**Cons:** SQLite doesn't handle DST transitions natively; the +1 offset is wrong for winter GMT; fragile
**Effort:** Medium
**Risk:** Medium

### Option C: Rescue `RecordNotUnique` and surface as validation error
In the controller, rescue `ActiveRecord::RecordNotUnique` and add a `base` validation error.

**Pros:** Belt-and-suspenders; works regardless of TZ mismatch
**Cons:** Doesn't fix the root cause; adds boilerplate to every write action
**Effort:** Small
**Risk:** Low (as a complement to Option A)

### Recommended Action

Option A, with Option C as a safety net. Align the validation to UTC to match the index, and add a `RecordNotUnique` rescue in the base controller for defence-in-depth.

## Technical Details

- Relevant model: likely `PeakFlowReading` or `DoseLog` (check migration for unique index on `recorded_at, user_id`)
- `Time.zone` is set to `"London"` in `config/application.rb`

## Acceptance Criteria

- [ ] A reading at 12:30am London BST does not raise `RecordNotUnique`
- [ ] The uniqueness validation and the SQLite index agree on "same day" semantics
- [ ] Unit test: two readings 30 minutes apart spanning London midnight vs UTC midnight

## Work Log

- 2026-03-12: Created from Milestone 2 code review — kieran-rails-reviewer HIGH finding
