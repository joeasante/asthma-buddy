---
status: pending
priority: p2
issue_id: "080"
tags: [code-review, security, data-integrity, rails, medical]
dependencies: []
---

# No Temporal Bounds Validation on `recorded_at` — Backdating and Future-Dating Allowed

## Problem Statement

Both `PeakFlowReading` and `PersonalBestRecord` accept any `recorded_at` timestamp with no bounds checking. A user (or agent) can submit readings backdated to before their account existed or future-dated arbitrarily. In a medical-adjacent app where zone classification informs treatment decisions, corrupted zone data carries genuine clinical risk.

**Backdating risk:** A backdated reading may predate all personal best records, causing `personal_best_at_reading_time` to return `nil` and the reading to be stored with `zone: nil` — incorrect medical data silently stored as "no zone".

**Future-dating risk:** A future-dated reading will appear first in `chronological` order queries. It will match any personal best records not yet entered, producing speculative zone data.

**Manipulation risk:** By carefully crafting `recorded_at`, a user could evaluate a reading against a specific historical personal best rather than their current one, gaming the zone classification.

## Findings

**Flagged by:** security-sentinel (F-05)

**Current validation** (`app/models/peak_flow_reading.rb:10`):
```ruby
validates :recorded_at, presence: true
```

No range constraints.

## Proposed Solutions

### Option A: Model validation with reasonable clinical bounds (Recommended)
**Effort:** Small | **Risk:** Low

```ruby
# app/models/peak_flow_reading.rb
validates :recorded_at, presence: true
validate :recorded_at_within_acceptable_range, if: -> { recorded_at.present? }

private

def recorded_at_within_acceptable_range
  if recorded_at > 5.minutes.from_now
    errors.add(:recorded_at, "cannot be in the future")
  elsif recorded_at < 1.year.ago
    errors.add(:recorded_at, "cannot be more than 1 year in the past")
  end
end
```

Apply same validation to `PersonalBestRecord`.

### Option B: Stricter bounds
**Effort:** Small | **Risk:** Low

Tighter bounds (e.g. 24 hours in the past, 5 minutes in the future) for stricter medical data integrity. May frustrate users who forget to log for a few days. 30 days may be a reasonable middle ground.

### Option C: Soft bounds (warn, don't block)
**Effort:** Medium | **Risk:** Low

Allow backdating with a UI warning. Block only future dates.

## Recommended Action

Option A — 1 year past, 5 minutes future. These bounds allow legitimate backdating (e.g. user forgot to log yesterday's reading) while preventing abuse and far-future speculative entries. Apply to both `PeakFlowReading` and `PersonalBestRecord`.

## Technical Details

**Affected files:**
- `app/models/peak_flow_reading.rb`
- `app/models/personal_best_record.rb`
- `test/models/peak_flow_reading_test.rb`
- `test/models/personal_best_record_test.rb`

## Acceptance Criteria

- [ ] Reading with `recorded_at` > 5 minutes in future is rejected with validation error
- [ ] Reading with `recorded_at` > 1 year in past is rejected with validation error
- [ ] Reading with `recorded_at` = yesterday is accepted
- [ ] Same bounds applied to `PersonalBestRecord`
- [ ] `bin/rails test` passes with 0 failures

## Work Log

- 2026-03-07: Identified by security-sentinel in Phase 6 code review
