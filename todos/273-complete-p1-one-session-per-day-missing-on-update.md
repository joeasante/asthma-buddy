---
status: complete
priority: p1
issue_id: "273"
tags: [code-review, rails, validation, database, peak-flow]
dependencies: []
---

# `one_session_per_day` validation not run on update — unhandled RecordNotUnique causes 500

## Problem Statement

The `one_session_per_day` validation in `PeakFlowReading` is declared `on: :create` only. The unique database index (`index_peak_flow_readings_unique_session_per_day`) enforces the constraint at the DB level for ALL operations, including updates.

If a user edits a reading and changes its `time_of_day` or `recorded_at` to collide with another existing reading, the Ruby validation silently passes (because `on: :create` skips it), the `UPDATE` SQL runs, the database raises `SQLite3::ConstraintException: UNIQUE constraint failed`, and Rails wraps it as `ActiveRecord::RecordNotUnique`. The `PeakFlowReadingsController#update` action does not rescue this exception — the user sees a 500 error page instead of a helpful validation message.

## Findings

- **File:** `app/models/peak_flow_reading.rb:20` — `validate :one_session_per_day, on: :create`
- **File:** `app/controllers/peak_flow_readings_controller.rb:162` — `update` action with no `rescue ActiveRecord::RecordNotUnique`
- **Agent:** data-migration-expert (migration safety review)
- The DB index is intentional as a TOCTOU guard for creates. But it creates an asymmetry on updates.

## Proposed Solutions

### Option A — Extend validation to also run `on: :update` (Recommended)

Change:
```ruby
validate :one_session_per_day, on: :create, if: -> { ... }
```
To:
```ruby
validate :one_session_per_day, on: %i[create update], if: -> { ... }
```

And modify `one_session_per_day` to exclude `self` on updates:
```ruby
def one_session_per_day
  return unless user
  date = recorded_at.to_date
  existing = user.peak_flow_readings
                 .where(time_of_day: time_of_day)
                 .where(recorded_at: date.beginning_of_day..date.end_of_day)
                 .where.not(id: id)  # exclude self on update
                 .first
  # ...
end
```

**Pros:** User-friendly error message. Consistent create/update behaviour.
**Effort:** Small
**Risk:** Low

### Option B — Rescue `ActiveRecord::RecordNotUnique` in controller update action

```ruby
rescue ActiveRecord::RecordNotUnique => e
  @peak_flow_reading.errors.add(:base, "You already have a #{@peak_flow_reading.time_of_day} reading for this date.")
  # render form error
end
```

**Pros:** Minimal model change.
**Cons:** Coupling DB exceptions to controller. Error message is generic.
**Effort:** Small
**Risk:** Low

## Recommended Action

Option A — model-level validation is the correct layer, with `.where.not(id: id)` to exclude self.

## Technical Details

- **Affected files:** `app/models/peak_flow_reading.rb`, `test/models/peak_flow_reading_test.rb`
- The `@duplicate_session_reading` instance variable pattern also needs to work on update path if using Option A

## Acceptance Criteria

- [ ] Editing a reading's `time_of_day` to conflict with another reading shows a validation error (not 500)
- [ ] Editing a reading's `recorded_at` to a date that conflicts shows a validation error
- [ ] Editing a reading without changing time_of_day/recorded_at succeeds
- [ ] Model test covers update-path duplicate detection

## Work Log

- 2026-03-11: Identified by data-migration-expert during migration safety review of dev branch
