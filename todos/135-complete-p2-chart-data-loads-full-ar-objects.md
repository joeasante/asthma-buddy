---
status: pending
priority: p2
issue_id: "135"
tags: [code-review, performance, peak-flow, charts]
dependencies: []
---

# Chart Data Loads 500 Full AR Objects Instead of Using Pluck

## Problem Statement

`PeakFlowReadingsController#index` instantiates up to 500 full ActiveRecord objects just to extract 3 scalar values (`recorded_at`, `value`, `zone`) for chart data. This is unnecessary memory and CPU overhead — `pluck` returns the same data as a raw SQL result without instantiating objects.

Flagged by: performance-oracle (high), kieran-rails-reviewer.

## Findings

**File:** `app/controllers/peak_flow_readings_controller.rb`, lines 62–64

```ruby
@chart_data = base_relation.reorder(recorded_at: :asc).limit(500).map do |r|
  { date: r.recorded_at.to_date.to_s, value: r.value, zone: r.zone }
end
```

Each AR object load triggers attribute type casting for every column in the `peak_flow_readings` table, not just the 3 needed. For 500 records, this is 500 object instantiations unnecessarily.

## Proposed Solution

```ruby
@chart_data = base_relation
  .reorder(recorded_at: :asc)
  .limit(500)
  .pluck(:recorded_at, :value, :zone)
  .map { |recorded_at, value, zone| { date: recorded_at.to_date.to_s, value: value, zone: zone } }
```

`pluck` returns arrays of raw scalar values. The `map` then shapes them into hashes exactly as before — but no AR objects are instantiated.

## Acceptance Criteria

- [ ] Chart data uses `pluck` instead of full object instantiation
- [ ] Chart renders identically in the browser
- [ ] Existing chart-related tests pass

## Work Log

- 2026-03-08: Identified by performance-oracle (high severity)
