---
phase: 28-rest-api
plan: 02
subsystem: api
tags: [rest-api, bearer-auth, pagination, json, pundit, rails]

requires:
  - phase: 28-rest-api
    provides: "API key infrastructure (ApiAuthenticatable concern, SHA-256 digest storage)"
provides:
  - "Api::V1::BaseController with Bearer token auth, pagination, date filtering, error handling"
  - "5 read-only JSON API endpoints: symptom_logs, peak_flow_readings, medications, dose_logs, health_events"
  - "Consistent JSON envelope format { data: [...], meta: { page, per_page, total } }"
  - "Current model supports direct user assignment for API auth flow"
affects: [28-03, 28-04, 28-05]

tech-stack:
  added: []
  patterns: ["ActionController::API base for lightweight API controllers", "Bearer token extraction + SHA-256 lookup", "Manual pagination with page/per_page/total meta", "Date range filtering via date_from/date_to params"]

key-files:
  created:
    - app/controllers/api/v1/base_controller.rb
    - app/controllers/api/v1/symptom_logs_controller.rb
    - app/controllers/api/v1/peak_flow_readings_controller.rb
    - app/controllers/api/v1/medications_controller.rb
    - app/controllers/api/v1/dose_logs_controller.rb
    - app/controllers/api/v1/health_events_controller.rb
    - test/controllers/api/v1/base_api_test_helper.rb
    - test/controllers/api/v1/symptom_logs_controller_test.rb
    - test/controllers/api/v1/peak_flow_readings_controller_test.rb
    - test/controllers/api/v1/medications_controller_test.rb
    - test/controllers/api/v1/dose_logs_controller_test.rb
    - test/controllers/api/v1/health_events_controller_test.rb
  modified:
    - config/routes.rb
    - app/models/current.rb

key-decisions:
  - "Inherited from ActionController::API (not ApplicationController) for lightweight stateless API"
  - "Added user attribute to Current model with fallback to session delegation for backwards compat"
  - "Used recorded_at (not occurred_on) for HealthEvent date filtering to match actual schema"
  - "Omitted title field from HealthEvent API response (column does not exist in schema)"

patterns-established:
  - "API controller pattern: inherit BaseController, authorize model, policy_scope, date_filter, paginate, render JSON"
  - "Error response format: { error: { status, message, details } } for all error types"
  - "API pagination: page (default 1), per_page (default 25, max 100), total in meta"

duration: 4min
completed: 2026-03-14
---

# Phase 28 Plan 02: REST API Endpoints Summary

**Versioned JSON API at /api/v1/ with Bearer auth, 5 read-only endpoints, pagination, date filtering, and 62 tests**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-14T21:16:04Z
- **Completed:** 2026-03-14T21:19:52Z
- **Tasks:** 2
- **Files modified:** 14

## Accomplishments
- Api::V1::BaseController with Bearer token authentication, Pundit authorization, pagination, date filtering, and consistent error handling
- 5 resource controllers (symptom_logs, peak_flow_readings, medications, dose_logs, health_events) with read-only index endpoints
- 62 comprehensive API tests covering auth, data scoping, pagination, filtering, and response format
- 743 total tests passing with no regressions

## Task Commits

Each task was committed atomically:

1. **Task 1: API base controller + routes + all 5 resource controllers** - `ff3c20c` (feat)
2. **Task 2: Comprehensive API controller tests (62 tests)** - `bdf8e21` (feat)

## Files Created/Modified
- `app/controllers/api/v1/base_controller.rb` - Base controller with Bearer auth, pagination, filtering, error handling
- `app/controllers/api/v1/symptom_logs_controller.rb` - Symptom logs index endpoint
- `app/controllers/api/v1/peak_flow_readings_controller.rb` - Peak flow readings index endpoint
- `app/controllers/api/v1/medications_controller.rb` - Medications index endpoint with eager-loaded dose_logs
- `app/controllers/api/v1/dose_logs_controller.rb` - Dose logs index endpoint with medication name
- `app/controllers/api/v1/health_events_controller.rb` - Health events index endpoint
- `config/routes.rb` - Added API namespace with 5 resource routes
- `app/models/current.rb` - Added user attribute for direct assignment in API flow
- `test/controllers/api/v1/base_api_test_helper.rb` - Shared API test helpers
- `test/controllers/api/v1/symptom_logs_controller_test.rb` - 20 tests
- `test/controllers/api/v1/peak_flow_readings_controller_test.rb` - 10 tests
- `test/controllers/api/v1/medications_controller_test.rb` - 10 tests
- `test/controllers/api/v1/dose_logs_controller_test.rb` - 11 tests
- `test/controllers/api/v1/health_events_controller_test.rb` - 11 tests

## Decisions Made
- Inherited from ActionController::API (not ApplicationController) -- lightweight, no session, no CSRF, no browser checks
- Added `user` attribute to Current model with fallback to `session.user` for backwards compatibility with web flow
- Used `recorded_at` for HealthEvent date filtering (plan referenced `occurred_on` which does not exist)
- Omitted `title` field from HealthEvent API response (column does not exist in schema)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] HealthEvent uses recorded_at, not occurred_on**
- **Found during:** Task 1 (resource controllers)
- **Issue:** Plan specified `occurred_on` as the date column for HealthEvent, but actual schema uses `recorded_at`
- **Fix:** Used `recorded_at` for ordering and date filtering
- **Files modified:** app/controllers/api/v1/health_events_controller.rb
- **Committed in:** ff3c20c (Task 1 commit)

**2. [Rule 1 - Bug] HealthEvent has no title column**
- **Found during:** Task 1 (resource controllers)
- **Issue:** Plan specified `title` field in HealthEvent response, but column does not exist
- **Fix:** Omitted title from response, included actual columns: id, event_type, recorded_at, created_at
- **Files modified:** app/controllers/api/v1/health_events_controller.rb
- **Committed in:** ff3c20c (Task 1 commit)

**3. [Rule 3 - Blocking] Current model lacks user= setter for API auth**
- **Found during:** Task 2 (tests revealed NoMethodError)
- **Issue:** Current model only had `session` attribute with `user` delegated from session; no way to set user directly for API auth
- **Fix:** Added `user` attribute to Current with fallback to `session&.user` for backwards compat
- **Files modified:** app/models/current.rb
- **Verification:** All 743 tests pass (62 new API + 681 existing)
- **Committed in:** bdf8e21 (Task 2 commit)

---

**Total deviations:** 3 auto-fixed (2 bug, 1 blocking)
**Impact on plan:** All fixes necessary for correctness. No scope creep.

## Issues Encountered
None beyond the auto-fixed deviations above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All 5 API endpoints operational with authentication, authorization, pagination, and filtering
- Ready for write endpoints (Plan 03), GDPR data export (Plan 04), or rate limiting (Plan 05)
- No blockers

## Self-Check: PASSED

All 13 key files verified present. Commits ff3c20c and bdf8e21 confirmed in git log.

---
*Phase: 28-rest-api*
*Completed: 2026-03-14*
