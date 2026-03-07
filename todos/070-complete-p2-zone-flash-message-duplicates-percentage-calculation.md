---
status: pending
priority: p2
issue_id: "070"
tags: [code-review, rails, architecture, performance]
dependencies: ["066"]
---

# `zone_flash_message` Re-derives Percentage Already Computed by Model — Add `zone_percentage` to Model

## Problem Statement

`PeakFlowReading#compute_zone` calculates `(value.to_f / pb) * 100` to determine the zone. `PeakFlowReadingsController#zone_flash_message` independently recalculates the same percentage for the flash string — calling `personal_best_at_reading_time` a second time (another DB query) and re-doing the same arithmetic. Two sources of truth for the same domain concept.

## Findings

**Flagged by:** kieran-rails-reviewer, performance-oracle

**Model (computes but discards percentage):**
```ruby
# app/models/peak_flow_reading.rb
def compute_zone
  pb = personal_best_at_reading_time
  return nil if pb.nil? || pb.zero?
  percentage = (value.to_f / pb) * 100   # computed, but not exposed
  if percentage >= 80; :green
  elsif percentage >= 50; :yellow
  else; :red; end
end
```

**Controller (re-derives the same percentage):**
```ruby
# app/controllers/peak_flow_readings_controller.rb
def zone_flash_message(reading)
  pb = reading.personal_best_at_reading_time  # second query (or third if not memoized)
  if pb.nil?
    "Reading saved — set your personal best to see your zone."
  else
    zone_label = reading.zone.capitalize
    percentage = ((reading.value.to_f / pb) * 100).round  # same arithmetic, again
    "Reading saved — #{zone_label} Zone (#{percentage}% of personal best)."
  end
end
```

The percentage is domain knowledge (how far from the threshold) — it belongs on the model, not derived in the controller. If the thresholds ever change (80%/50%), the percentage display formula must be updated in both places.

Note: This ticket is separate from 066 (memoization). Even with memoization in place, `zone_flash_message` still calls `personal_best_at_reading_time` and re-derives the percentage. Both fixes are needed.

## Proposed Solution

Add `zone_percentage` as a model method and simplify the controller:

```ruby
# app/models/peak_flow_reading.rb
def zone_percentage
  pb = personal_best_at_reading_time
  return nil if pb.nil? || pb.zero?
  ((value.to_f / pb) * 100).round
end
```

Controller becomes:
```ruby
def zone_flash_message(reading)
  if reading.zone.nil?
    "Reading saved — set your personal best to see your zone."
  else
    "Reading saved — #{reading.zone.capitalize} Zone (#{reading.zone_percentage}% of personal best)."
  end
end
```

With memoization (066) in place, `personal_best_at_reading_time` is called once for `compute_zone` (in `before_save`) and zero additional times thereafter — `zone_percentage` reuses the memoized result.

**Effort:** Small
**Risk:** Zero

## Acceptance Criteria

- [ ] `PeakFlowReading#zone_percentage` added to model (returns rounded integer or nil)
- [ ] `zone_flash_message` in controller uses `reading.zone.nil?` check and `reading.zone_percentage`
- [ ] No duplicate `personal_best_at_reading_time` arithmetic in the controller
- [ ] Model test added for `zone_percentage` (green/yellow/red/nil cases)
- [ ] All 142 existing tests still pass

## Work Log

- 2026-03-07: Identified by kieran-rails-reviewer and performance-oracle during Phase 6 code review
