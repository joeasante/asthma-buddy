---
status: pending
priority: p3
issue_id: "300"
tags: [code-review, rails, performance, dashboard]
dependencies: ["298"]
---

# @total_reading/symptom/health_event_count queries run on JSON requests unnecessarily

## Problem Statement
`DashboardController#index` computes `@total_reading_count`, `@total_symptom_count`, and `@total_health_event_count` unconditionally. These three COUNT queries exist solely to power "View all N" footer links on the HTML dashboard. Neither appears in the `format.json` response block. If the dashboard JSON endpoint is used (e.g., polled by a mobile app), three COUNT queries fire on every request without contributing to the response.

## Findings
**Flagged by:** performance-oracle

**File:** `app/controllers/dashboard_controller.rb`

```ruby
@total_reading_count      = user.peak_flow_readings.count   # used only in HTML
@total_symptom_count      = user.symptom_logs.count         # used only in HTML
@total_health_event_count = user.health_events.count        # used only in HTML
```

All three drive "View all N" links in the ERB template. None appear in the `render json:` block.

## Proposed Solutions
### Option A — Move inside format.html block
If the `respond_to` block is retained, move these three queries inside it:
```ruby
format.html do
  @total_reading_count      = user.peak_flow_readings.count
  @total_symptom_count      = user.symptom_logs.count
  @total_health_event_count = user.health_events.count
end
```
**Note:** If todo 298 is resolved (dashboard JSON removed), this todo becomes moot — the queries can stay unconditional since there's no JSON path to waste them on.
**Effort:** Trivial.

## Recommended Action

## Technical Details
- **File:** `app/controllers/dashboard_controller.rb`
- **Dependency:** Resolving todo 298 (remove dashboard JSON) also closes this todo

## Acceptance Criteria
- [ ] Either: counts moved inside `format.html` block, OR todo 298 resolved (JSON removed)

## Work Log
- 2026-03-12: Code review finding — performance-oracle

## Resources
- Branch: dev
