---
status: complete
priority: p1
issue_id: "191"
tags: [code-review, agent-native, api, phase-15-1]
dependencies: []
---

# `RelieverUsageController#index` Has No JSON Format Handler — Feature Is Agent-Opaque

## Problem Statement
`RelieverUsageController#index` has no `respond_to` block. `GET /reliever-usage.json` raises `ActionController::UnknownFormat` (406 Not Acceptable). The entire Reliever Usage History feature — weekly bars, GINA bands, monthly stats, peak flow correlation — is invisible to agents and API clients. This violates the project's documented agent-native convention in `ApplicationController` (lines 15–17) which requires `format.json` on all data actions.

## Findings
- **File:** `app/controllers/reliever_usage_controller.rb:4-43`
- Zero agent-accessible capabilities from this feature (0/7)
- `ApplicationController` at lines 15–17 explicitly documents the JSON parity requirement
- `PeakFlowReadingsController` is the reference implementation with full CRUD JSON support
- Agent-native reviewer scored this feature 0/7 on agent accessibility

## Proposed Solutions

### Option A (Recommended): Add `respond_to` block with JSON branch
```ruby
def index
  # ... existing setup ...

  respond_to do |format|
    format.html
    format.json do
      render json: {
        weeks: @weeks,
        weekly_data: @weekly_data.map { |w|
          { week_start: w[:week_start], week_end: w[:week_end],
            uses: w[:uses], band: w[:band].to_s, label: w[:label] }
        },
        monthly_uses: @monthly_uses,
        monthly_status: @monthly_pill_label,
        correlation: @correlation,
        gina_bands: { controlled: "0-2 uses/week", review: "3-5 uses/week", urgent: "6+ uses/week" }
      }
    end
  end
end
```
- Effort: Small
- Risk: None

### Option B: Dedicated JSON serialiser method (matches `PeakFlowReadingsController` pattern)
Extract `reliever_usage_json` private method and call it from the respond_to block. Keeps the action clean and provides a single edit point for the JSON shape.
- Effort: Small
- Risk: None

## Recommended Action

## Technical Details
- Affected files: `app/controllers/reliever_usage_controller.rb`
- Reference: `app/controllers/peak_flow_readings_controller.rb` (JSON pattern)

## Acceptance Criteria
- [ ] `GET /reliever-usage.json` returns 200 with JSON payload
- [ ] Payload includes `weekly_data` array with `uses`, `band` (string), `label` per week
- [ ] Payload includes `monthly_uses` and `monthly_status`
- [ ] Payload includes `correlation` (or null)
- [ ] Unauthenticated request returns 401 JSON (already handled by `Authentication` concern)
- [ ] Test added for JSON format response

## Work Log
- 2026-03-10: Identified by agent-native-reviewer as P1 in Phase 15.1 review
