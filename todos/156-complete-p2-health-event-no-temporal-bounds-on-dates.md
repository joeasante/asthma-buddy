---
status: pending
priority: p2
issue_id: "156"
tags: [code-review, security, validation, health-events]
dependencies: []
---

# No Temporal Bounds on `recorded_at` / `ended_at`

## Problem Statement

`HealthEvent` validates `recorded_at` for presence only. No upper or lower bounds are enforced. Future-dated events pollute the 7-day dashboard chart window; far-future `ended_at` values render events as "Ongoing" indefinitely even when they should have resolved. A previous review found the same issue on `PeakFlowReading#recorded_at` (todo #080, now complete) — the same pattern must apply here.

## Findings

**Flagged by:** security-sentinel (P2)

**Location:** `app/models/health_event.rb`

**Current validations:**
```ruby
validates :recorded_at, presence: true
validate :ended_at_after_recorded_at
```

**Missing:**
- `recorded_at` can be `9999-12-31` — appears at top of `recent_first` list forever; if within the current week, pollutes chart markers
- `recorded_at` can be `1900-01-01` — produces misleading historical data
- `ended_at` can be `2099-01-01` with `recorded_at: Date.current` — passes `ended_at_after_recorded_at`, stores as a valid event, shows as "Ongoing" badge for 73 years

**Clock skew note:** A `+1.minute` grace window is appropriate for the upper bound — browser clocks can be slightly ahead of the server.

## Proposed Solutions

### Option A — Add bound validations to model (Recommended)

```ruby
# app/models/health_event.rb

EARLIEST_VALID_DATE = Date.new(1900, 1, 1)

validate :recorded_at_within_bounds
validate :ended_at_within_bounds

private

def recorded_at_within_bounds
  return unless recorded_at.present?
  if recorded_at > Time.current + 1.minute
    errors.add(:recorded_at, "cannot be in the future")
  elsif recorded_at.to_date < EARLIEST_VALID_DATE
    errors.add(:recorded_at, "is too far in the past")
  end
end

def ended_at_within_bounds
  return unless ended_at.present?
  if ended_at > Time.current + 1.minute
    errors.add(:ended_at, "cannot be in the future")
  end
end
```

**Effort:** Small
**Risk:** Low

## Acceptance Criteria

- [ ] `HealthEvent.new(event_type: :illness, recorded_at: 1.day.from_now).valid?` returns `false`
- [ ] `HealthEvent.new(event_type: :illness, recorded_at: Date.current, ended_at: 1.year.from_now).valid?` returns `false`
- [ ] Model tests cover both bound validations
- [ ] `bin/rails test test/models/health_event_test.rb` passes

## Work Log

- 2026-03-09: Identified by security-sentinel during `ce:review`. Same pattern as todo #080 (peak_flow_reading temporal bounds, now complete).
