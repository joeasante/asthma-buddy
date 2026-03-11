---
status: complete
priority: p2
issue_id: "280"
tags: [code-review, rails, api, agent-native, peak-flow]
dependencies: []
---

# Peak flow create JSON 422 response omits duplicate reading info

## Problem Statement

When `PeakFlowReadingsController#create` fails due to the `one_session_per_day` validation, `@duplicate_reading` is set with the conflicting reading. The Turbo Stream response uses this to offer the user a link to the conflicting reading. The JSON error response returns only `{ errors: [...] }` — the conflicting reading's ID and metadata are absent.

An agent receiving a 422 on peak flow create cannot identify which specific reading is the conflict. It cannot present "you already have a morning reading today (ID 42, value 380 L/min) — would you like to update that one instead?"

## Findings

- **File:** `app/controllers/peak_flow_readings_controller.rb:148–153`
- **Agent:** agent-native-reviewer

```ruby
# Current — JSON error path omits @duplicate_reading
format.json { render json: { errors: @peak_flow_reading.errors.full_messages }, status: :unprocessable_entity }
```

## Proposed Solutions

### Option A — Include duplicate reading in JSON 422 (Recommended)

```ruby
json_response = { errors: @peak_flow_reading.errors.full_messages }
if @duplicate_reading.present?
  json_response[:duplicate_reading] = peak_flow_reading_json(@duplicate_reading)
end
render json: json_response, status: :unprocessable_entity
```

**Pros:** Agent can act on the conflict intelligently.
**Effort:** Trivial
**Risk:** None

## Recommended Action

Option A.

## Technical Details

- **Affected file:** `app/controllers/peak_flow_readings_controller.rb`

## Acceptance Criteria

- [ ] POST `/peak-flow-readings.json` with a duplicate session returns 422 with `duplicate_reading` in the body
- [ ] `duplicate_reading` includes `id`, `value`, `recorded_at`, `zone`
- [ ] Controller test covers this JSON path

## Work Log

- 2026-03-11: Identified by agent-native-reviewer during code review of dev branch
