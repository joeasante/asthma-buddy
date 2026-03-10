---
status: pending
priority: p3
issue_id: "179"
tags: [code-review, simplicity, views, peak-flow]
dependencies: []
---

# group_by and sort_by Data Operations Belong in Controller, Not View

## Problem Statement
index.html.erb does `@peak_flow_readings.group_by { |r| r.recorded_at.to_date }` and `readings.sort_by { |r| r.morning? ? 0 : 1 }` directly in the template. Views should be pure rendering layers. The sort_by can be pushed to a DB-level secondary sort on the chronological scope. The group_by can be pre-computed in the controller as `@grouped_readings`.

## Proposed Solutions

### Option A
In the controller, after paginating: `@grouped_readings = @peak_flow_readings.to_a.group_by { |r| r.recorded_at.to_date }` (values already in chronological order). Add a DB-level `time_of_day` sort to the scope or a `morning_first` scope: `reorder('recorded_at DESC, CASE time_of_day WHEN \'morning\' THEN 0 ELSE 1 END ASC')`. Remove both operations from the view.
- Effort: Small
- Risk: Low

## Recommended Action

## Technical Details
- Affected files: app/controllers/peak_flow_readings_controller.rb, app/views/peak_flow_readings/index.html.erb, app/models/peak_flow_reading.rb (optional scope)

## Acceptance Criteria
- [ ] Controller assigns `@grouped_readings` as a hash keyed by date
- [ ] DB-level secondary sort replaces `sort_by` in the view
- [ ] View iterates `@grouped_readings` directly with no Ruby data operations
- [ ] Existing behaviour (date grouping, morning-first order) is preserved

## Work Log
- 2026-03-10: Created via code review
