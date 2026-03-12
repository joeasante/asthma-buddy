---
status: pending
priority: p3
issue_id: "304"
tags: [code-review, rails, yagni, health-events, api]
dependencies: ["295"]
---

# illness_symptom_logs in health_event_json has no test assertion and fires a duplicate query

## Problem Statement
`HealthEventsController#health_event_json` includes an `illness_symptom_logs` key for illness events. No controller test asserts this key exists in the JSON response. The HTML `show` action already loads `@illness_symptom_logs` with the correct `includes(:rich_text_notes)`, but `health_event_json` runs a second independent query without the includes — causing N+1 on `to_plain_text` calls (addressed in todo 295). If no consumer currently relies on `illness_symptom_logs` in the JSON response, removing it eliminates the duplicate query entirely.

## Findings
**Flagged by:** code-simplicity-reviewer, performance-oracle

**File:** `app/controllers/health_events_controller.rb` — `health_event_json`

The HTML show view uses `@illness_symptom_logs` (justified). The JSON API includes `illness_symptom_logs` (speculative — no test, no consumer).

## Proposed Solutions
### Option A — Remove illness_symptom_logs from health_event_json (Recommended if no consumer)
Remove the 10-line block inside `health_event_json`. The HTML path is unaffected (`health_event_json` is not called for HTML).
**Pros:** Eliminates the duplicate query and the N+1 from todo 295 at once. **Effort:** Small. **Risk:** None (no consumer).

### Option B — Keep and fix the N+1 (todo 295)
If a consumer exists or is imminent, fix the N+1 by adding `.includes(:rich_text_notes)` and add a test asserting the key.
**Effort:** Trivial. **Risk:** None.

## Recommended Action

## Technical Details
- **File:** `app/controllers/health_events_controller.rb` — `health_event_json`, lines ~95-105
- **Dependency:** If option A, resolves todo 295 as a side effect

## Acceptance Criteria
- [ ] Either: `illness_symptom_logs` removed from JSON response, OR
- [ ] `illness_symptom_logs` is tested and the N+1 from todo 295 is fixed

## Work Log
- 2026-03-12: Code review finding — code-simplicity-reviewer

## Resources
- Branch: dev
