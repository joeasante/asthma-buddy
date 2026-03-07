---
status: pending
priority: p1
issue_id: "091"
tags: [code-review, agent-native, api, rails, peak-flow]
dependencies: []
---

# `PeakFlowReadingsController#update` missing `format.json` — violates ApplicationController contract

## Problem Statement

`update` has no `format.json` branch. `ApplicationController` has a written convention: "Every resource action that creates/modifies data must support `format.json` so agents can call endpoints programmatically." A JSON client sending `PATCH /peak-flow-readings/:id` with `Accept: application/json` receives a 406 Not Acceptable. `create` already has full JSON parity; `update` does not.

## Findings

**Flagged by:** agent-native-reviewer, security-sentinel, architecture-strategist (P1/P2 consensus)

**Location:** `app/controllers/peak_flow_readings_controller.rb:90-102`

```ruby
def update
  if @peak_flow_reading.update(peak_flow_reading_params)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to peak_flow_readings_path, notice: "Reading updated." }
      # format.json missing → 406 for JSON clients
    end
  else
    respond_to do |format|
      format.turbo_stream { render :update_error, status: :unprocessable_entity }
      format.html { render :edit, status: :unprocessable_entity }
      # format.json missing → 406 for JSON clients
    end
  end
end
```

## Proposed Solutions

### Option A: Add `format.json` to both success and failure branches (Recommended)

```ruby
def update
  if @peak_flow_reading.update(peak_flow_reading_params)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to peak_flow_readings_path, notice: "Reading updated." }
      format.json { render json: peak_flow_reading_json(@peak_flow_reading) }
    end
  else
    respond_to do |format|
      format.turbo_stream { render :update_error, status: :unprocessable_entity }
      format.html { render :edit, status: :unprocessable_entity }
      format.json { render json: { errors: @peak_flow_reading.errors.full_messages }, status: :unprocessable_entity }
    end
  end
end
```

The `peak_flow_reading_json` private method already exists (line 126) and can be reused directly.

- **Pros:** Consistent with `create`; uses existing serialiser; matches ApplicationController convention
- **Effort:** Small
- **Risk:** None

## Recommended Action

Option A.

## Technical Details

- **Affected files:** `app/controllers/peak_flow_readings_controller.rb`
- **Components:** PeakFlowReadingsController#update

## Acceptance Criteria

- [ ] `PATCH /peak-flow-readings/:id` with `Accept: application/json` and valid params → 200 + JSON reading body
- [ ] `PATCH /peak-flow-readings/:id` with `Accept: application/json` and blank value → 422 + `{ errors: [...] }`
- [ ] `PATCH /peak-flow-readings/:id` for another user's reading → 404 (from set_peak_flow_reading)
- [ ] Add controller tests for both branches
- [ ] All 170 existing tests still pass

## Work Log

- 2026-03-07: Identified during Phase 7 code review by agent-native-reviewer, security-sentinel, architecture-strategist
