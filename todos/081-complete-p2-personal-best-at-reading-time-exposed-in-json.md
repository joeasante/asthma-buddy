---
status: pending
priority: p2
issue_id: "081"
tags: [code-review, security, privacy, phi, api]
dependencies: []
---

# `personal_best_at_reading_time` Exposed in JSON Create Response (PHI Concern)

## Problem Statement

The `POST /peak-flow-readings` JSON create response includes `personal_best_at_reading_time` — the user's historical personal best lung function value at the time of the reading. Combined with the reading value and timestamp already in the response, this field allows inference of health trajectory over time. It is PHI unnecessary for confirming a reading was created.

The app explicitly filters health data from logs (`filter_parameter_logging.rb`) — this same mindset of minimal necessary disclosure should apply to API responses. A future audit of PHI exposure would flag this field.

## Findings

**Flagged by:** security-sentinel (F-04)

**Current** (`app/controllers/peak_flow_readings_controller.rb:57–67`):
```ruby
def peak_flow_reading_json(reading)
  {
    id: reading.id,
    value: reading.value,
    recorded_at: reading.recorded_at,
    zone: reading.zone,
    zone_percentage: reading.zone_percentage,
    personal_best_at_reading_time: reading.personal_best_at_reading_time,  # ← PHI
    created_at: reading.created_at
  }
end
```

An agent confirming a reading was stored needs `id`, `value`, `recorded_at`, `zone`, and `zone_percentage`. The `personal_best_at_reading_time` is not needed to confirm creation.

## Proposed Solutions

### Option A: Remove from create response (Recommended)
**Effort:** Tiny | **Risk:** Low

Remove `personal_best_at_reading_time` from `peak_flow_reading_json`. If the zone and zone_percentage are present, the agent can infer a personal best exists. The exact value of the personal best is derivable if the agent wants it via `GET /settings`.

### Option B: Expose via separate endpoint
**Effort:** Small | **Risk:** Low

Keep `peak_flow_reading_json` lean, expose `personal_best_at_reading_time` only on a dedicated `GET /peak-flow-readings/:id` or `GET /settings` endpoint where access is explicit and auditable.

### Option C: Keep but document
**Effort:** Tiny | **Risk:** Low

Add a comment documenting the deliberate PHI disclosure decision. Acceptable if there is a specific agent workflow that requires the personal best value from the create response.

## Recommended Action

Option A — remove the field. The `zone_percentage` already encodes the relationship between the reading value and personal best (`pct = value / personal_best * 100`). The raw personal best value is redundant and adds PHI surface area without enabling new agent capabilities.

## Technical Details

**Affected files:**
- `app/controllers/peak_flow_readings_controller.rb`
- `test/controllers/peak_flow_readings_controller_test.rb` (update JSON response test)

## Acceptance Criteria

- [ ] JSON create response does not include `personal_best_at_reading_time`
- [ ] JSON create response still includes `id`, `value`, `recorded_at`, `zone`, `zone_percentage`, `created_at`
- [ ] `bin/rails test` passes with 0 failures

## Work Log

- 2026-03-07: Identified by security-sentinel in Phase 6 code review
