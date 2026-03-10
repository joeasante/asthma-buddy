---
status: pending
priority: p1
issue_id: "206"
tags: [code-review, agent-native, api, json, dose-logs]
dependencies: []
---

# `Settings::DoseLogsController` Has No `format.json` — Agents Cannot Log or Delete Doses

## Problem Statement

`Settings::DoseLogsController#create` and `#destroy` respond only to `format.turbo_stream` and `format.html`. Any request with `Accept: application/json` raises `ActionController::UnknownFormat` (406). The `GET /reliever-usage.json` endpoint added in Phase 15.1 tells an agent that a user's GINA status is "Speak to your GP" — but there is no programmatic path for that agent to log the dose event that triggered the state, or to help maintain a complete dose history. Read parity exists; write parity is completely absent.

This violates the project's agent-native requirement (documented in `ApplicationController` lines 15–17: "Every resource action a user can take, an agent must also be able to take").

## Findings

**Flagged by:** agent-native-reviewer (P1)

**Location:** `app/controllers/settings/dose_logs_controller.rb` lines 8–33

**Current `create` action (simplified):**
```ruby
def create
  @dose_log = DoseLog.new(dose_log_params)
  if @dose_log.save
    respond_to do |format|
      format.turbo_stream { ... }
      format.html { redirect_to ... }
    end
  else
    respond_to do |format|
      format.turbo_stream { ... }
      format.html { redirect_to ... }
    end
  end
end
```

No `format.json` branch — returns 406 to JSON clients.

**Precedent in codebase:** `PeakFlowReadingsController` and `SymptomLogsController` both have `format.json` branches on create/destroy following the `ApplicationController` requirement.

## Proposed Solutions

### Option A — Add `format.json` to `create` and `destroy` (Recommended)
**Effort:** Small | **Risk:** Low

```ruby
# create — success
format.json { render json: dose_log_json(@dose_log), status: :created }

# create — failure
format.json { render json: { errors: @dose_log.errors.full_messages }, status: :unprocessable_entity }

# destroy
format.json { head :no_content }
```

Add private helper:
```ruby
def dose_log_json(dose_log)
  {
    id:            dose_log.id,
    medication_id: dose_log.medication_id,
    puffs:         dose_log.puffs,
    recorded_at:   dose_log.recorded_at
  }
end
```

Add tests to `test/controllers/settings/dose_logs_controller_test.rb`:
- `POST /settings/medications/:id/dose_logs.json` → 201 with correct JSON
- `POST /settings/medications/:id/dose_logs.json` with invalid params → 422 with errors
- `DELETE /settings/medications/:id/dose_logs/:id.json` → 204
- Unauthenticated JSON POST → 401

### Option B — Defer until API layer is formally scoped
**Effort:** None | **Risk:** Agent parity gap persists

**Pros:** No work required.
**Cons:** Violates ApplicationController convention. Agent cannot log doses until fixed.

## Recommended Action

Option A. Follow the `PeakFlowReadingsController` pattern exactly. The `dose_log_json` serialiser should match the field set an agent needs to confirm a successful log: id, medication_id, puffs, recorded_at.

## Technical Details

- **Affected files:** `app/controllers/settings/dose_logs_controller.rb`, `test/controllers/settings/dose_logs_controller_test.rb`
- **Related issue:** Todo 207 (MedicationsController missing format.json — agent needs medication IDs to log doses)

## Acceptance Criteria

- [ ] `POST /settings/medications/:id/dose_logs` with `Accept: application/json` returns 201 with JSON body
- [ ] `POST` with invalid params returns 422 with `{ errors: [...] }` JSON
- [ ] `DELETE /settings/medications/:id/dose_logs/:id` with JSON returns 204
- [ ] Unauthenticated JSON requests return 401
- [ ] Tests cover all above cases

## Work Log

- 2026-03-10: Identified by agent-native-reviewer. Agent-native score: 3/9 capabilities accessible. Write surface entirely absent.

## Resources

- Precedent: `app/controllers/peak_flow_readings_controller.rb` (format.json pattern)
- ApplicationController agent-native requirement: lines 15–17
- Related: Todo 207 (MedicationsController JSON)
