---
status: pending
priority: p1
issue_id: "127"
tags: [code-review, performance, n-plus-one, database]
dependencies: []
---

# N+1 UPDATE Loop in `recompute_nil_zone_readings`

## Problem Statement

`PersonalBestRecord#recompute_nil_zone_readings` issues one `UPDATE` query per nil-zone reading. A first-time user importing 200 historical readings triggers 201+ queries (1 personal best save + 200 updates), which can take 10–40 seconds and timeout in production. This is a regression introduced with the `after_save` callback.

Flagged by: kieran-rails-reviewer (blocker), performance-oracle (critical).

## Findings

**File:** `app/models/personal_best_record.rb`, `recompute_nil_zone_readings` method

```ruby
def recompute_nil_zone_readings
  user.peak_flow_readings.where(zone: nil).each do |reading|
    pct = (reading.value.to_f / value) * 100
    new_zone = if pct >= PeakFlowReading::GREEN_ZONE_THRESHOLD then "green"
               elsif pct >= PeakFlowReading::YELLOW_ZONE_THRESHOLD then "yellow"
               else "red"
               end
    reading.update_column(:zone, PeakFlowReading.zones[new_zone])
  end
end
```

Each `update_column` is a separate SQL statement. For 200 nil-zone readings, this is 200 UPDATE queries.

Additionally, this callback fires on **every save** to `PersonalBestRecord` (any attribute change), not just when `value` changes. If a future attribute is added, every update to it triggers the expensive loop unnecessarily.

## Proposed Solutions

**Solution A — Single bulk UPDATE per zone using SQL CASE (recommended):**
```ruby
def recompute_nil_zone_readings
  nil_zone_readings = user.peak_flow_readings.where(zone: nil).to_a
  return if nil_zone_readings.empty?

  green_ids  = []
  yellow_ids = []
  red_ids    = []

  nil_zone_readings.each do |reading|
    pct = (reading.value.to_f / value) * 100
    if pct >= PeakFlowReading::GREEN_ZONE_THRESHOLD
      green_ids  << reading.id
    elsif pct >= PeakFlowReading::YELLOW_ZONE_THRESHOLD
      yellow_ids << reading.id
    else
      red_ids    << reading.id
    end
  end

  PeakFlowReading.where(id: green_ids).update_all(zone: PeakFlowReading.zones["green"])   unless green_ids.empty?
  PeakFlowReading.where(id: yellow_ids).update_all(zone: PeakFlowReading.zones["yellow"]) unless yellow_ids.empty?
  PeakFlowReading.where(id: red_ids).update_all(zone: PeakFlowReading.zones["red"])       unless red_ids.empty?
end
```
This reduces 200 UPDATEs to a maximum of 3 UPDATE statements regardless of record count.

- Pros: O(1) queries vs O(n), handles 10,000 readings as easily as 10
- Cons: Slightly more complex grouping logic
- Effort: Small

**Solution B — Guard with `if: -> { saved_change_to_value? || previously_new_record? }`:**
```ruby
after_save :recompute_nil_zone_readings, if: -> { saved_change_to_value? || previously_new_record? }
```
This prevents the callback from firing on unrelated saves. Should be combined with Solution A, not used instead of it.

- Pros: Avoids unnecessary work on unrelated attribute saves
- Cons: Does not fix the per-row UPDATE problem
- Effort: Trivial

## Recommended Action

Apply both Solution A (bulk UPDATE) and Solution B (guard condition) together.

## Technical Details

- **Affected files:** `app/models/personal_best_record.rb`
- **Related migration:** `20260308130000_backfill_nil_zone_peak_flow_readings.rb` uses the same pattern and should also be bulk-updated (but is a one-time migration, so lower priority)

## Acceptance Criteria

- [ ] `recompute_nil_zone_readings` issues at most 3 UPDATE statements regardless of nil-zone reading count
- [ ] Callback only fires when `value` changes or record is new
- [ ] All existing zone-related tests pass
- [ ] Add a test that creates 50 nil-zone readings, saves a personal best, and asserts correct zones with `assert_queries` guard (max 5 queries)

## Work Log

- 2026-03-08: Identified by code review agents (kieran-rails-reviewer as blocker, performance-oracle as critical)
