---
status: pending
priority: p1
issue_id: "163"
tags: [code-review, testing, security, show-pages]
dependencies: []
---

# No Tests for New Show Actions — Cross-User Isolation Untested

## Problem Statement

Three new show actions were added (PeakFlowReadings, SymptomLogs, HealthEvents) with zero test coverage. In a health app where data isolation is the primary security concern, show actions must be tested for: (1) returns 200 for own record, (2) returns 404 for another user's record (cross-user IDOR check), (3) redirects unauthenticated user. PeakFlowReadingsController#show has a 4th case: renders correctly with and without a personal best.

## Findings

All three controllers expose a show action added during the show-pages redesign phase. None of the existing controller test files include cases for these actions. The absence of cross-user isolation tests means an IDOR vulnerability could be introduced (or already present) without any failing signal. For a medical data application this is an unacceptable gap — data isolation is the primary security requirement.

## Proposed Solutions

### Option A: Add tests inline to existing test files

Add test cases directly to the existing controller test files, following the established pattern: `sign_in(@user)`, `get path`, `assert_response :success` / `:not_found`. Cover the four required cases for peak flow and three for the others.

- Pros: Minimal overhead, consistent with existing test style, immediately actionable
- Cons: None
- Effort: Small
- Risk: Low

## Recommended Action

(leave blank — fill during triage)

## Technical Details

- Affected files:
  - test/controllers/peak_flow_readings_controller_test.rb
  - test/controllers/symptom_logs_controller_test.rb
  - test/controllers/health_events_controller_test.rb

## Acceptance Criteria

- [ ] PeakFlowReadingsController#show returns 200 for own record
- [ ] PeakFlowReadingsController#show returns 404 for another user's record
- [ ] PeakFlowReadingsController#show redirects unauthenticated user
- [ ] PeakFlowReadingsController#show renders correctly when personal best is present
- [ ] PeakFlowReadingsController#show renders correctly when personal best is absent
- [ ] SymptomLogsController#show returns 200 for own record
- [ ] SymptomLogsController#show returns 404 for another user's record
- [ ] SymptomLogsController#show redirects unauthenticated user
- [ ] HealthEventsController#show returns 200 for own record
- [ ] HealthEventsController#show returns 404 for another user's record
- [ ] HealthEventsController#show redirects unauthenticated user

## Work Log

- 2026-03-10: Created via code review

## Resources

- Code review of show pages + peak flow redesign
