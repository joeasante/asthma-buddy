---
status: pending
priority: p2
issue_id: "171"
tags: [code-review, performance, turbo, peak-flow]
dependencies: []
---

# @header_last_reading and @header_month_count Fire on Every Turbo Frame Filter Request

## Problem Statement
`PeakFlowReadingsController#index` always assigns `@header_last_reading` and `@header_month_count`. These instance variables feed the page-header stat area which sits outside the `readings_content` Turbo Frame. When a user clicks a filter chip, Turbo issues a GET to the index action, Rails executes the full action (including both header queries), but only the `readings_content` frame content is used by Turbo — the header HTML is discarded entirely. These 2 queries run on every filter navigation with their results never reaching the browser.

## Findings
- `@header_last_reading`: queries `peak_flow_readings` ordered chronologically with `LIMIT 1`
- `@header_month_count`: queries `peak_flow_readings` with a `WHERE recorded_at >= beginning_of_month` count
- Both are referenced only in the header partial, which is outside the `readings_content` Turbo Frame
- On filter chip clicks, Turbo sends a full GET request but only replaces the `readings_content` frame — header queries fire and their results are immediately discarded
- `turbo_frame_request?` is already available in Rails controllers as a helper to detect this case

## Proposed Solutions

### Option A
Guard both header queries behind `unless turbo_frame_request?`:

```ruby
unless turbo_frame_request?
  @header_last_reading = Current.user.peak_flow_readings.chronological.first
  @header_month_count  = Current.user.peak_flow_readings.where(recorded_at: Date.current.beginning_of_month..).count
end
```

This eliminates both queries on every Turbo Frame filter navigation while keeping them for full page loads where the header is actually rendered.
- Pros: Eliminates 2 wasted queries per filter interaction; idiomatic Rails/Turbo pattern; zero-risk change — header is not rendered on frame requests regardless
- Cons: None
- Effort: Small
- Risk: Low

## Recommended Action

## Technical Details
- Affected files:
  - `app/controllers/peak_flow_readings_controller.rb`

## Acceptance Criteria
- [ ] `@header_last_reading` and `@header_month_count` are not queried when `turbo_frame_request?` is true
- [ ] Both queries continue to run on full page loads (non-frame requests)
- [ ] Header stat area displays correctly on initial page load and after full navigation
- [ ] Filter chip interactions continue to work correctly

## Work Log
- 2026-03-10: Created via code review
