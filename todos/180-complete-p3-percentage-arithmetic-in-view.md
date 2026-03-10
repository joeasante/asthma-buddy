---
status: pending
priority: p3
issue_id: "180"
tags: [code-review, simplicity, views, peak-flow]
dependencies: []
---

# Zone Percentage Arithmetic Computed in View Template

## Problem Statement
index.html.erb computes `((@period_avg.to_f / @current_personal_best.value) * 100).round` twice — once for period avg, once for period best. Raw arithmetic in ERB templates is hard to test, duplicates intent, and requires `@current_personal_best` non-nil guard. The controller already has both values; it should also assign `@period_avg_pct` and `@period_best_pct`.

## Proposed Solutions

### Option A
In the controller, after computing @period_avg and @period_best: `@period_avg_pct = @current_personal_best && @period_avg ? ((@period_avg.to_f / @current_personal_best.value) * 100).round : nil`. Same for @period_best_pct. View uses `<% if @period_avg_pct %>` and `<%= @period_avg_pct %>`.
- Effort: Small
- Risk: Low

## Recommended Action

## Technical Details
- Affected files: app/controllers/peak_flow_readings_controller.rb, app/views/peak_flow_readings/index.html.erb

## Acceptance Criteria
- [ ] Controller assigns `@period_avg_pct` and `@period_best_pct` (Integer or nil)
- [ ] View contains no arithmetic expressions — only conditional display of assigned ivars
- [ ] nil case renders gracefully (no percentage shown when PB is absent)

## Work Log
- 2026-03-10: Created via code review
