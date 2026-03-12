---
status: complete
priority: p2
issue_id: "328"
tags: [code-review, agent-native, json, dashboard]
dependencies: []
---

# `DashboardController#index` Missing JSON Response

## Problem Statement

`DashboardController#index` has no `format.json` branch. This means agents and API clients cannot retrieve the user's dashboard summary data programmatically. The dashboard aggregates the most important health data (recent peak flow, symptom trends, medication adherence) — it's the most valuable endpoint for an agent to query when assessing a user's current health state.

## Findings

**Flagged by:** agent-native-reviewer (rated CRITICAL gap)

- `DashboardController#index`: no `respond_to` block, HTML-only
- Agents cannot answer "what's the user's current health status?" without a JSON dashboard endpoint
- `SettingsController#show` also lacks JSON (separate todo)

## Proposed Solutions

### Option A: Add `respond_to` block with JSON summary
```ruby
def index
  # ... existing HTML setup ...
  respond_to do |format|
    format.html
    format.json do
      render json: {
        peak_flow: {
          latest: @latest_reading&.as_json(only: %i[value recorded_at zone]),
          personal_best: @personal_best
        },
        symptoms: {
          recent_count: @recent_symptom_count,
          latest: @latest_symptom&.as_json(only: %i[symptom_type severity recorded_at])
        },
        medications: {
          low_stock_count: @low_stock_count,
          due_today: @medications_due_today&.map { |m| m.as_json(only: %i[id name]) }
        }
      }
    end
  end
end
```

**Pros:** Enables agent health queries; consistent with project JSON API pattern
**Cons:** Requires deciding exactly which fields to expose
**Effort:** Small-Medium
**Risk:** Low

### Option B: Separate `/dashboard.json` endpoint
Create a dedicated `DashboardSummaryController` for API consumers.

**Pros:** Clean separation
**Cons:** Unnecessary — the existing controller already computes all the data
**Effort:** Medium
**Risk:** Low

### Recommended Action

Option A — add JSON branch to existing controller following project convention.

## Technical Details

- **File:** `app/controllers/dashboard_controller.rb`
- Refer to `PeakFlowReadingsController` and `SymptomLogsController` for the project's JSON response conventions

## Acceptance Criteria

- [ ] `GET /dashboard.json` returns a JSON summary of current health data
- [ ] Response includes peak flow, symptoms, and medication fields
- [ ] Controller test covers the JSON format
- [ ] Agent can query dashboard without HTML parsing

## Work Log

- 2026-03-12: Created from Milestone 2 code review — agent-native-reviewer CRITICAL finding
