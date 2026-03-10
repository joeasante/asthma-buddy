---
status: pending
priority: p3
issue_id: "186"
tags: [code-review, performance, show-pages, peak-flow]
dependencies: []
---

# Peak Flow Show Page Makes Two Personal Best Queries (Controller + zone_percentage)

## Problem Statement
PeakFlowReadingsController#show loads `@personal_best = PersonalBestRecord.current_for(Current.user)` (current PB). The view then calls `@peak_flow_reading.zone_percentage` which fires a second query to find the historical PB at reading time. This is a different query (historical vs current) but both fire on a single-record show page. The controller already has the PB in hand and could compute the percentage directly.

## Proposed Solutions

### Option A
In the show action, compute `@zone_percentage = @personal_best && @peak_flow_reading.zone ? (@peak_flow_reading.value.to_f / @personal_best.value * 100).round : nil`. Use `@zone_percentage` in the view instead of `@peak_flow_reading.zone_percentage`. Note: uses current PB not historical PB — minor approximation acceptable for a show page.
- Effort: Small
- Risk: Low

## Recommended Action

## Technical Details
- Affected files: app/controllers/peak_flow_readings_controller.rb, app/views/peak_flow_readings/show.html.erb

## Acceptance Criteria
- [ ] Show action assigns `@zone_percentage` (Integer or nil)
- [ ] View renders `@zone_percentage` directly without calling `zone_percentage` on the model
- [ ] No additional PB query fires on the show page (verify via query log or bullet gem)

## Work Log
- 2026-03-10: Created via code review
