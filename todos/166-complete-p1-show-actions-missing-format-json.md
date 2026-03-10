---
status: pending
priority: p1
issue_id: "166"
tags: [code-review, agent-native, json-api, show-pages]
dependencies: []
---

# Three New Show Actions Lack format.json — Agent Clients Get 406

## Problem Statement

All three new show actions (PeakFlowReadingsController#show, SymptomLogsController#show, HealthEventsController#show) are HTML-only. An agent or API client sending `Accept: application/json` or requesting `.json` receives 406 Not Acceptable. Private serialiser helpers (`peak_flow_reading_json`, `symptom_log_json`) already exist in the first two controllers and can be used directly. HealthEventsController has no serialiser helper at all — one must be added. Additionally, HealthEventsController has no format.json on ANY action (index, create, update, destroy) making the entire resource opaque to agent clients.

## Findings

The show-pages redesign added HTML show actions without wiring a JSON response format. The project has an established agent-native convention: every read endpoint must respond to `format.json` using a private serialiser helper. This convention is implemented on PeakFlowReadingsController (index, create, update, destroy) and SymptomLogsController (index, create, update, destroy). The three new show actions break the pattern. HealthEventsController is the most severe case — it has no JSON coverage on any action.

## Proposed Solutions

### Option A: Add respond_to blocks to all three show actions; add health_event_json helper

Add `respond_to` blocks to the show actions in all three controllers. For PeakFlowReadingsController and SymptomLogsController, use the existing `peak_flow_reading_json` and `symptom_log_json` helpers respectively. For HealthEventsController, add a private `health_event_json` helper returning: `{ id, event_type, event_type_label, ongoing, recorded_at, ended_at, formatted_duration, notes_plain_text }`. Track full HealthEventsController JSON coverage (create/update/destroy/index) as a separate follow-on P2 issue.

- Pros: Restores agent-native parity, uses existing serialiser pattern, isolated change
- Cons: HealthEventsController still lacks JSON on write actions until the follow-on is addressed
- Effort: Small for peak_flow_readings + symptom_logs; Medium for health_events (new helper required)
- Risk: Low

## Recommended Action

(leave blank — fill during triage)

## Technical Details

- Affected files:
  - app/controllers/peak_flow_readings_controller.rb
  - app/controllers/symptom_logs_controller.rb
  - app/controllers/health_events_controller.rb

## Acceptance Criteria

- [ ] GET /peak-flow-readings/:id.json returns 200 with JSON body
- [ ] GET /symptom-logs/:id.json returns 200 with JSON body
- [ ] GET /medical-history/:id.json returns 200 with JSON body
- [ ] All three JSON responses include the same fields as their corresponding HTML view
- [ ] health_event_json helper returns: id, event_type, event_type_label, ongoing, recorded_at, ended_at, formatted_duration, notes_plain_text
- [ ] Unauthenticated JSON requests return 401, not a redirect

## Work Log

- 2026-03-10: Created via code review

## Resources

- Code review of show pages + peak flow redesign
