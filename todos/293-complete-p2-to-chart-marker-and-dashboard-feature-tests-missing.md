---
status: pending
priority: p2
issue_id: "293"
tags: [code-review, rails, testing, coverage]
dependencies: ["289"]
---

# Missing tests: to_chart_marker model, dashboard new features, onboarding step1 redirect

## Problem Statement
Several new features and refactors in the dev branch have no test coverage: (1) `HealthEvent#to_chart_marker` has no model tests despite being extracted as a shared method used by two controllers; (2) new `DashboardController` variables (`@active_illness`, `@reliever_medications`, `@todays_best_reading`) are not tested; (3) the `redirect_if_step1_done` removal has no test documenting the new permitted behaviour.

## Findings
**Flagged by:** kieran-rails-reviewer, architecture-strategist

Missing test coverage:
1. `test/models/health_event_test.rb` — no `to_chart_marker` tests (point-in-time with ended_at, duration with ended_at, duration without ended_at)
2. `test/controllers/dashboard_controller_test.rb` — no tests for: `@active_illness` nil when no illness; `@reliever_medications` excludes courses; `@todays_best_reading` returns highest value today; `today-doses-list` turbo stream in DoseLogsController create response
3. `test/controllers/onboarding_controller_test.rb` — no test: step 1 accessible (or redirects) when `onboarding_personal_best_done: true`
4. `test/controllers/settings/dose_logs_controller_test.rb` — create action does not assert `today-doses-list` turbo stream target in response body

## Proposed Solutions

### Option A — Add targeted unit and controller tests
Write the missing tests directly:
- 3 model tests for `to_chart_marker` in `health_event_test.rb`
- 4 controller tests in `dashboard_controller_test.rb`
- 1 controller test in `onboarding_controller_test.rb`
- 1 assertion in `dose_logs_controller_test.rb` create test
**Effort:** Small. **Risk:** None.

## Recommended Action

## Technical Details
- **Files:** `test/models/health_event_test.rb`, `test/controllers/dashboard_controller_test.rb`, `test/controllers/onboarding_controller_test.rb`, `test/controllers/settings/dose_logs_controller_test.rb`

## Acceptance Criteria
- [ ] `to_chart_marker` has model tests for point-in-time event, duration event with ended_at, duration event without ended_at
- [ ] Dashboard controller test asserts `@active_illness` nil when no ongoing illness
- [ ] Dashboard controller test asserts `@reliever_medications` excludes course medications
- [ ] DoseLogsController create test asserts `today-doses-list` appears in turbo stream response
- [ ] Onboarding step 1 access with personal_best_done=true has a documented test

## Work Log
- 2026-03-12: Code review finding — kieran-rails-reviewer and architecture-strategist

## Resources
- Branch: dev
