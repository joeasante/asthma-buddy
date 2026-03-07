---
status: pending
priority: p3
issue_id: "088"
tags: [code-review, rails, quality, medical]
dependencies: []
---

# Zone Threshold Magic Numbers — No Named Constants

## Problem Statement

The zone thresholds (80% for Green, 50% for Yellow) in `PeakFlowReading#compute_zone` are hardcoded magic numbers. These are clinically meaningful values (standard British Thoracic Society peak flow zone definitions). If a future feature needs to display threshold boundaries (e.g. "you need 416 L/min to reach Green Zone") or if thresholds ever become user-configurable, there is no single source of truth to reference.

## Findings

**Flagged by:** architecture-strategist (P2), code-simplicity-reviewer

**Current** (`app/models/peak_flow_reading.rb:24–37`):
```ruby
def compute_zone
  pb = personal_best_at_reading_time
  return nil if pb.nil? || pb.zero?

  percentage = (value.to_f / pb) * 100
  if percentage >= 80    # ← magic number
    :green
  elsif percentage >= 50 # ← magic number
    :yellow
  else
    :red
  end
end
```

## Proposed Solutions

### Option A: Named constants on the model (Recommended)
**Effort:** Tiny | **Risk:** Very Low

```ruby
class PeakFlowReading < ApplicationRecord
  GREEN_ZONE_THRESHOLD  = 80  # ≥80% of personal best (British Thoracic Society guidelines)
  YELLOW_ZONE_THRESHOLD = 50  # 50–79% of personal best

  def compute_zone
    pct = zone_pct
    return nil if pct.nil?
    if pct >= GREEN_ZONE_THRESHOLD then :green
    elsif pct >= YELLOW_ZONE_THRESHOLD then :yellow
    else :red
    end
  end
end
```

### Option B: Extract to a configuration file
**Effort:** Small | **Risk:** Low

If thresholds might become user-configurable or vary by condition (e.g. paediatric vs adult thresholds), store in a YAML config file and load at startup.

## Recommended Action

Option A — named constants on the model. Simple, no new files, communicates clinical meaning.

## Technical Details

**Affected files:**
- `app/models/peak_flow_reading.rb`

## Acceptance Criteria

- [ ] `GREEN_ZONE_THRESHOLD = 80` and `YELLOW_ZONE_THRESHOLD = 50` constants defined on `PeakFlowReading`
- [ ] `compute_zone` references constants (not magic numbers)
- [ ] `bin/rails test` passes with 0 failures

## Work Log

- 2026-03-07: Identified by architecture-strategist in Phase 6 code review
