---
phase: 03-symptom-recording
plan: 02
subsystem: controllers-views
tags: [rails, turbo-streams, actiontext, hotwire, multi-user-isolation, controller-tests]

# Dependency graph
requires:
  - phase: 03-01
    provides: SymptomLog model with enums, has_rich_text :notes, chronological scope, alice_wheezing/bob_coughing fixtures
  - phase: 02-authentication
    provides: Authentication concern, Current.user, sign_in_as test helper, session routes
provides:
  - SymptomLogsController with user-scoped index and create actions
  - GET /symptom_logs (index) and POST /symptom_logs (create) routes
  - index.html.erb with turbo_frame_tag sections for form and entry list
  - _form.html.erb with symptom_type select, severity select, datetime-local, Trix rich_text_area
  - _symptom_log.html.erb with semantic dl/dt/dd, dom_id, iso8601 datetime
  - create.turbo_stream.erb: prepend entry to list + replace form with fresh blank on success
  - 7 integration tests covering auth gates, isolation, Turbo Stream, 422 on invalid
affects: [03-03-system-tests, 03-04-turbo-streams, phase-4-edit-delete, phase-5-timeline]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Turbo Stream dual-format: format.turbo_stream (auto-render template) on success, explicit turbo_stream.replace with 422 on failure"
    - "All queries via Current.user.symptom_logs association — never SymptomLog.all or unscoped"
    - "includes(:rich_text_notes) on index query to prevent N+1 for ActionText notes"
    - "sign_in_as helper used in controller tests (consistent with existing test suite)"

key-files:
  created:
    - app/controllers/symptom_logs_controller.rb
    - app/views/symptom_logs/index.html.erb
    - app/views/symptom_logs/_form.html.erb
    - app/views/symptom_logs/_symptom_log.html.erb
    - app/views/symptom_logs/create.turbo_stream.erb
    - test/controllers/symptom_logs_controller_test.rb
  modified:
    - config/routes.rb

key-decisions:
  - "sign_in_as helper used instead of POST session_url — consistent with existing test suite pattern and avoids hardcoding fixture password"
  - "turbo_frame_tag wraps both form and list sections — enables targeted Turbo Stream replace/prepend by DOM id"
  - "422 status on validation failure is required so Turbo Drive processes the error stream instead of treating it as a redirect"

# Metrics
duration: ~4min
completed: 2026-03-07
---

# Phase 3 Plan 02: SymptomLogs Controller, Views, and Turbo Stream Summary

**SymptomLogsController with user-scoped index/create, Turbo Stream response (prepend entry + clear form on success, inline 422 errors on failure), and 7 passing integration tests covering auth gates and multi-user isolation**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-03-07T09:02:41Z
- **Completed:** 2026-03-07T09:05:50Z
- **Tasks:** 3 of 3
- **Files modified:** 7

## Accomplishments

- Added `resources :symptom_logs, only: [:index, :create]` to routes
- Created SymptomLogsController with user-scoped index (`Current.user.symptom_logs.chronological.includes(:rich_text_notes)`) and create actions; no unscoped SymptomLog access anywhere
- Turbo Stream success path: `create.turbo_stream.erb` prepends new entry to `symptom_logs_list` and replaces `symptom_log_form` with a fresh blank form
- Turbo Stream failure path: replaces form with validation errors at HTTP 422 (required for Turbo to process the error response)
- index.html.erb with two `turbo_frame_tag` sections matching the DOM ids used in the Turbo Stream response
- _form.html.erb with all four inputs: symptom_type select (from enum keys), severity select, datetime-local field (pre-filled with Time.current), and Trix rich_text_area for notes
- _symptom_log.html.erb with semantic `<dl>/<dt>/<dd>`, `dom_id`, `<time datetime>`, and notes guarded by `present?`
- 7 integration tests pass; full 55-test suite green with no regressions

## Task Commits

Each task was committed atomically:

1. **Task 1: Routes, controller, and Turbo Stream response** - `7f7ce99` (feat)
2. **Task 2: Views — index, form partial, entry partial** - `d100dab` (feat)
3. **Task 3: Controller integration tests** - `5b102b3` (feat)

## Files Created/Modified

- `config/routes.rb` - Added `resources :symptom_logs, only: [:index, :create]`
- `app/controllers/symptom_logs_controller.rb` - SymptomLogsController with user-scoped index and create, strong params, dual Turbo Stream/HTML responses
- `app/views/symptom_logs/create.turbo_stream.erb` - prepend to symptom_logs_list + replace symptom_log_form with fresh form
- `app/views/symptom_logs/index.html.erb` - Two turbo_frame_tag sections; conditional empty state message
- `app/views/symptom_logs/_form.html.erb` - All four form fields with ARIA error display, enum-derived select options
- `app/views/symptom_logs/_symptom_log.html.erb` - Semantic dl/dt/dd entry with dom_id and iso8601 datetime
- `test/controllers/symptom_logs_controller_test.rb` - 7 integration tests

## Decisions Made

- `sign_in_as` helper used in tests instead of `POST session_url` with raw password — the helper is already established in the codebase (`test/test_helpers/session_test_helper.rb`) and is cleaner than hardcoding fixture credentials. The plan specified `password: "password"` but fixtures use `password123`.
- `turbo_frame_tag` wraps both the form and the list, making both sections targetable by Turbo Stream actions via their DOM ids (`symptom_log_form` and `symptom_logs_list`).
- HTTP 422 on validation failure is intentional and required — Turbo Drive ignores Turbo Stream responses at 2xx status from form errors, treating them as successes.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Used sign_in_as helper instead of wrong password in test setup**
- **Found during:** Task 3
- **Issue:** The plan's test setup used `post session_url, params: { ..., password: "password" }` but fixtures define passwords as `password123`. This would cause all 7 tests to fail with authentication redirects.
- **Fix:** Used the `sign_in_as(@user)` / `sign_out` helpers already established in `test/test_helpers/session_test_helper.rb`, consistent with the rest of the test suite (e.g. `sessions_controller_test.rb` uses `sign_in_as`).
- **Files modified:** `test/controllers/symptom_logs_controller_test.rb`
- **Commit:** `5b102b3`

## Issues Encountered

None.

## User Setup Required

None.

## Next Phase Readiness

- `/symptom_logs` page is fully functional: form renders, submission creates entry via Turbo Stream, validation errors appear inline, form clears after success
- Multi-user isolation verified at both controller query level (`Current.user.symptom_logs`) and test level (alice_wheezing present, bob_coughing absent)
- dom_id on entry partial (`symptom_log_123`) is ready for Phase 4 edit/delete targeting
- `chronological` scope + `includes(:rich_text_notes)` ready for Phase 5 timeline
- No blockers — Plan 03 (system tests) can start immediately

---
*Phase: 03-symptom-recording*
*Completed: 2026-03-07*

## Self-Check: PASSED

- app/controllers/symptom_logs_controller.rb: FOUND
- app/views/symptom_logs/index.html.erb: FOUND
- app/views/symptom_logs/_form.html.erb: FOUND
- app/views/symptom_logs/_symptom_log.html.erb: FOUND
- app/views/symptom_logs/create.turbo_stream.erb: FOUND
- test/controllers/symptom_logs_controller_test.rb: FOUND
- config/routes.rb: FOUND
- Commit 7f7ce99: FOUND
- Commit d100dab: FOUND
- Commit 5b102b3: FOUND
