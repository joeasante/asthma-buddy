---
status: pending
priority: p2
issue_id: "174"
tags: [code-review, agent-native, json-api, health-events]
dependencies: []
---

# HealthEventsController Has No format.json on Any Action

## Problem Statement
Unlike PeakFlowReadingsController and SymptomLogsController which have full JSON API coverage on all write actions, HealthEventsController has zero JSON support. create calls redirect_to directly. update calls redirect_to directly. destroy has only turbo_stream and html. index groups events for HTML only. An agent cannot create, update, delete, or list health events via the API. Since health events include hospitalisations, GP appointments, and medication changes, this is the most clinically significant data gap in the API surface.

## Proposed Solutions

### Option A
Add respond_to blocks with format.json to all HealthEventsController actions (index, create, update, destroy). Add a private `health_event_json` helper returning `{ id, event_type, event_type_label, ongoing, recorded_at, ended_at, formatted_duration, notes_plain_text }`.
- Effort: Medium
- Risk: Low

## Recommended Action

## Technical Details
- Affected files: app/controllers/health_events_controller.rb

## Acceptance Criteria
- [ ] index returns JSON array of health events with all specified fields
- [ ] create returns JSON of the created record on success, errors on failure
- [ ] update returns JSON of the updated record on success, errors on failure
- [ ] destroy returns a JSON confirmation on success
- [ ] `health_event_json` private helper is implemented with all specified fields
- [ ] JSON responses are consistent in shape with PeakFlowReadingsController and SymptomLogsController equivalents
- [ ] Existing HTML and turbo_stream responses are not broken

## Work Log
- 2026-03-10: Created via code review
