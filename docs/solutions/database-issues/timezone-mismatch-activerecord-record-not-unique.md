---
title: "UTC/London timezone mismatch causes ActiveRecord::RecordNotUnique in uniqueness validation"
problem_type: runtime-error
component: "PeakFlowReading model, database unique index"
tags: [timezone, sqlite, bst, validation, recordnotunique, activerecord, uniqueness]
symptoms:
  - ActiveRecord::RecordNotUnique raised at database layer rather than caught by the model validation
  - Unhandled 500 error for London users between 23:00–00:00 UTC during British Summer Time
  - Uniqueness validation passes but database constraint fires for the same recording
root_cause: "Ruby validation used local-time (London) date boundaries via Date#beginning_of_day, but the SQLite unique index used DATE(recorded_at) which operates in UTC. During BST (UTC+1), one hour per day the two disagree on which calendar day a timestamp belongs to."
---

# UTC/London Timezone Mismatch — `ActiveRecord::RecordNotUnique` in Uniqueness Validation

## Problem

`PeakFlowReading` enforces one session (morning/evening) per day using a model validation **and** a database unique index. The two were written with different timezone assumptions:

- **Ruby validation** computed day boundaries using `Date#beginning_of_day`, which respects `Time.zone` (London)
- **SQLite unique index** used `DATE(recorded_at)`, which operates in UTC

During British Summer Time (last Sunday of March → last Sunday of October), London is UTC+1. A reading recorded between midnight and 1am London time (23:00–00:00 UTC) belongs to:
- **London date**: the new calendar day (e.g. June 16)
- **UTC date** (what the DB index sees): the previous calendar day (e.g. June 15)

The validation passed (no London-June-16 reading existed), but the DB index found a UTC-June-15 conflict and raised `ActiveRecord::RecordNotUnique` — an unhandled exception, not a clean validation error.

## Root Cause

```ruby
# BEFORE — mismatched timezone domains
def one_session_per_day
  return unless user
  date = recorded_at.to_date                      # London date
  existing = user.peak_flow_readings
                 .where(time_of_day: time_of_day)
                 .where(recorded_at: date.beginning_of_day..date.end_of_day)  # London range
                 .first
  # ... validation passes ...
end
```

```sql
-- The database index uses UTC:
CREATE UNIQUE INDEX index_peak_flow_readings_unique_session_per_day
  ON peak_flow_readings (user_id, time_of_day, DATE(recorded_at));
-- DATE(recorded_at) evaluates in UTC
```

During BST, a recording at 23:30 UTC on June 15 (`= 00:30 London June 16`):
- Ruby sees London date June 16 → no existing morning reading → **validation passes**
- DB sees UTC date June 15 → existing morning reading on June 15 → **constraint fires** → `RecordNotUnique`

## Solution

Align the Ruby validation to use UTC day boundaries, matching the database index:

```ruby
# AFTER — both use UTC
def one_session_per_day
  return unless user
  # Use UTC day boundaries to match the database unique index (DATE(recorded_at) in SQLite
  # uses UTC). This prevents ActiveRecord::RecordNotUnique for London users between
  # 23:00–00:00 UTC during BST, where Ruby's local-time date differs from the UTC date.
  utc_start = recorded_at.utc.beginning_of_day
  utc_end   = recorded_at.utc.end_of_day
  existing = user.peak_flow_readings
                 .where(time_of_day: time_of_day)
                 .where(recorded_at: utc_start..utc_end)
                 .first
  return unless existing

  @duplicate_session_reading = existing
  local_date = recorded_at.to_date   # still use local date for the error message
  label = local_date == Date.current ? "today" : local_date.strftime("%-d %b")
  errors.add(:base, "You already have a #{time_of_day} reading for #{label}.")
end
```

Key insight: the error message still uses `recorded_at.to_date` (London time) so it reads correctly to the user — only the **query** switches to UTC.

## Prevention

### Rule of thumb
When a Rails app is configured with a non-UTC `Time.zone` and SQLite stores datetimes in UTC:
- SQL functions like `DATE()`, `STRFTIME()` always operate in UTC
- Rails `Date#beginning_of_day` uses `Time.zone`
- These two will **disagree by up to 1 hour** when the timezone is UTC+N

**Contract to enforce:** any Ruby code that constructs a day-range query for a column that also has a `DATE(col)`-based unique index must use `recorded_at.utc.beginning_of_day` / `recorded_at.utc.end_of_day`, not `Date#beginning_of_day`.

### Code review signals
- A model validation uses `date.beginning_of_day..date.end_of_day` and the same column has a `DATE(col)` unique index in the schema
- `db/schema.rb` contains a SQLite expression index like `"user_id, DATE(recorded_at)"` — check that all Ruby queries against that column use UTC arithmetic

### Test pattern

```ruby
# Test BST boundary: 23:30 UTC = 00:30 London (next calendar day)
test "duplicate validation fires at UTC-day boundary during BST" do
  travel_to Time.utc(2026, 6, 15, 23, 30) do  # BST: London sees June 16, 00:30
    first = PeakFlowReading.create!(
      user: @user, value: 450, time_of_day: :morning,
      recorded_at: Time.current
    )
    assert first.persisted?

    # A second morning reading at the same UTC time — should be rejected, not raise
    second = PeakFlowReading.new(
      user: @user, value: 460, time_of_day: :morning,
      recorded_at: Time.current
    )
    assert_not second.valid?
    assert_match /already have a morning reading/, second.errors[:base].first
  end
end
```

## Related

- `db/schema.rb`: `index_peak_flow_readings_unique_session_per_day` — the expression index
- `app/models/peak_flow_reading.rb` — `one_session_per_day` validation
- Rails `Time.zone` configured in `config/application.rb`
- SQLite stores all datetimes in UTC regardless of `Time.zone`
