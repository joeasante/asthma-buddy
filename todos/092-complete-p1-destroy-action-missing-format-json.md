---
status: pending
priority: p1
issue_id: "092"
tags: [code-review, agent-native, api, rails, peak-flow]
dependencies: []
---

# `PeakFlowReadingsController#destroy` missing `format.json` — violates ApplicationController contract

## Problem Statement

`destroy` has no `format.json` branch. A JSON client sending `DELETE /peak-flow-readings/:id` with `Accept: application/json` receives a 406 Not Acceptable. `SymptomLogsController#destroy` includes `format.json { head :no_content }` — peak flow is inconsistent. The `ApplicationController` convention requires all mutating actions to support JSON.

## Findings

**Flagged by:** agent-native-reviewer, security-sentinel, architecture-strategist, pattern-recognition-specialist

**Location:** `app/controllers/peak_flow_readings_controller.rb:104-110`

```ruby
def destroy
  @peak_flow_reading.destroy
  respond_to do |format|
    format.turbo_stream
    format.html { redirect_to peak_flow_readings_path, notice: "Reading deleted." }
    # format.json missing → 406 for JSON clients
  end
end
```

## Proposed Solutions

### Option A: Add `format.json { head :no_content }` (Recommended)

```ruby
def destroy
  @peak_flow_reading.destroy
  respond_to do |format|
    format.turbo_stream
    format.html { redirect_to peak_flow_readings_path, notice: "Reading deleted." }
    format.json { head :no_content }
  end
end
```

Matches `SymptomLogsController#destroy` exactly. One line change.

- **Pros:** Standard REST 204; consistent with peer controller; one line
- **Effort:** Tiny
- **Risk:** None

## Recommended Action

Option A.

## Technical Details

- **Affected files:** `app/controllers/peak_flow_readings_controller.rb`

## Acceptance Criteria

- [ ] `DELETE /peak-flow-readings/:id` with `Accept: application/json` → 204 No Content
- [ ] Cross-user `DELETE` with JSON → 404
- [ ] Unauthenticated `DELETE` with JSON → redirect (existing auth behaviour unchanged)
- [ ] Add controller test for JSON destroy 204
- [ ] All 170 existing tests pass

## Work Log

- 2026-03-07: Identified during Phase 7 code review
