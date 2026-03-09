---
status: pending
priority: p1
issue_id: "112"
tags: [code-review, performance, database, peak-flow, charts, rails]
dependencies: []
---

# Unbounded peak flow chart query — all readings loaded into Ruby memory

## Problem Statement

`PeakFlowReadingsController#index` builds chart data by calling `.reorder(recorded_at: :asc)` on `base_relation` and then `.map`-ing over every result in Ruby. `base_relation` is the filtered relation for the current page's time range but has no record count cap. A user with 1,000+ readings will load all 1,000+ records into memory just to build a chart JSON array. The paginated list itself uses Kaminari with 20 per page, but the chart query bypasses pagination entirely.

## Findings

- `app/controllers/peak_flow_readings_controller.rb` — chart data built with `base_relation.reorder(recorded_at: :asc).map { |r| { ... } }`
- `base_relation` is scoped to a date range but has no `.limit`
- For a 90-day range with multiple readings per day, this could easily be 270+ records
- `app/controllers/symptom_logs_controller.rb#build_chart_data` uses SQL aggregation (`GROUP BY DATE(...)`) — correct approach not replicated in peak flow

## Proposed Solutions

### Option A: Cap with a LIMIT (Recommended near-term)
```ruby
@chart_data = base_relation.reorder(recorded_at: :asc).limit(500).map do |r|
  { date: r.recorded_at.to_date.to_s, value: r.value, zone: r.zone }
end
```
**Pros:** Quick fix, bounded memory.
**Cons:** Arbitrary cap; doesn't aggregate — you still get 500 individual points.
**Effort:** Small | **Risk:** Low

### Option B: SQL aggregation (Recommended long-term)
Aggregate to one data point per day (daily average or last reading of day):
```ruby
@chart_data = base_relation
  .select("DATE(recorded_at) as date, AVG(value) as avg_value")
  .group("DATE(recorded_at)")
  .order("DATE(recorded_at) ASC")
  .map { |r| { date: r.date, value: r.avg_value.round, zone: PeakFlowReading.zone_for(r.avg_value.round, personal_best) } }
```
**Pros:** O(days) not O(readings); correct chart shape.
**Cons:** Needs a class method `PeakFlowReading.zone_for`.
**Effort:** Medium | **Risk:** Low

## Recommended Action

Option A as a quick fix; Option B as follow-up.

## Technical Details

- **Affected files:** `app/controllers/peak_flow_readings_controller.rb`
- **Performance impact:** Linear in total reading count for the selected date range

## Acceptance Criteria

- [ ] Chart data query is bounded (either by `.limit` or by SQL aggregation)
- [ ] Chart renders correctly for users with many readings
- [ ] No N+1 queries introduced

## Work Log

- 2026-03-08: Identified by performance-oracle during PR review
