---
phase: 11-medication-management-ui
plan: 03
subsystem: testing
tags: [rails, minitest, capybara, selenium, turbo, system-tests, integration-tests]

# Dependency graph
requires:
  - phase: 11-01
    provides: Settings::MedicationsController with CRUD actions and cross-user isolation
  - phase: 11-02
    provides: Medication views (index, card, form, turbo stream responses, inline edit)
provides:
  - Controller integration tests for all 6 CRUD actions + cross-user isolation
  - System tests for add, inline edit, remove, isolation, and unauthenticated redirect
affects:
  - Future phases adding medication behaviour (dose logging, low stock warnings)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - System test sign_in_as asserts dashboard_url (app redirects authenticated root to /dashboard)
    - Custom Turbo confirm dialog tested via confirm_dialog helper clicking btn-confirm-delete
    - Optional field assertions use DOM verification (visit index, assert_text) not DB direct queries
    - Controller cross-user tests use Current.user.medications.find which auto-raises RecordNotFound -> 404

key-files:
  created:
    - test/controllers/settings/medications_controller_test.rb
    - test/system/medication_management_test.rb
  modified: []

key-decisions:
  - "sign_in_as in system tests asserts dashboard_url not root_url — HomeController redirects authenticated users to /dashboard"
  - "confirm_controller.js replaces native browser confirm with custom <dialog> modal — accept_confirm capybara helper does not work; test clicks confirm#accept button directly"
  - "Optional fields system test verifies via DOM (navigate to index, assert card shows sick-day/doses fields) not direct DB query — SQLite WAL + transactional tests cross-thread visibility is unreliable"

patterns-established:
  - "Settings controller tests live under test/controllers/settings/ mirroring app/controllers/settings/"
  - "Cross-user isolation tests use @other_medication fixture and assert_response :not_found"

# Metrics
duration: 8min
completed: 2026-03-08
---

# Phase 11 Plan 03: Medication Management Tests Summary

**Controller integration tests (15 tests) and system tests (6 tests) for medication CRUD, Turbo Stream responses, cross-user 404 isolation, and browser-level add/edit/remove flows via the custom confirm dialog.**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-03-08T16:59:37Z
- **Completed:** 2026-03-08T17:07:40Z
- **Tasks:** 2
- **Files created:** 2

## Accomplishments
- 15 controller integration tests cover all 6 actions (index, new, create, edit, update, destroy), authentication redirect, user scoping, Turbo Stream response type, and cross-user 404 on edit/update/destroy
- 6 system tests cover add medication (flash confirm + list appearance), optional fields visible in card, inline edit via Turbo Frame, remove via custom confirm dialog, cross-user URL isolation, unauthenticated redirect
- Full test suite: 256 tests, 0 failures (grew from 241)

## Task Commits

Each task was committed atomically:

1. **Task 1: Controller integration tests (CRUD + cross-user isolation)** - `8fa710e` (test)
2. **Task 2: System tests for add, edit, and remove medication flows** - `fbbcd17` (test)

**Plan metadata:** (to follow in docs commit)

## Files Created/Modified
- `test/controllers/settings/medications_controller_test.rb` - 15 integration tests for all CRUD actions, Turbo Stream media type, cross-user 404, optional fields persistence, auth redirect
- `test/system/medication_management_test.rb` - 6 Capybara/Selenium system tests for add, optional fields, inline edit, remove, cross-user isolation, unauthenticated redirect

## Decisions Made
- **dashboard_url in sign_in_as**: After sign-in the app lands on `/dashboard` not `/` (HomeController redirects authenticated users). `assert_current_path dashboard_url` is the correct assertion.
- **Custom confirm dialog**: The app uses `confirm_controller.js` (Stimulus) which replaces native `window.confirm` with a `<dialog>` modal. Capybara's `accept_confirm` helper only intercepts native dialogs. Tests click `dialog.confirm-dialog button[data-action='confirm#accept']` directly.
- **DOM assertions for optional fields**: Direct `Medication.find_by` calls in system tests are unreliable because Capybara and the test thread use separate DB connections in SQLite WAL mode with transactional tests. Asserting on DOM (navigate to index, check card text) is the correct pattern.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed sign_in_as to assert dashboard_url instead of root_url**
- **Found during:** Task 2 (system tests)
- **Issue:** Plan template used `assert_current_path root_url` in `sign_in_as`, but `HomeController#index` redirects authenticated users to `/dashboard`. All sign-in assertions failed.
- **Fix:** Changed `assert_current_path root_url` to `assert_current_path dashboard_url` in the new system test helper.
- **Files modified:** test/system/medication_management_test.rb
- **Verification:** All 6 system tests pass
- **Committed in:** fbbcd17 (Task 2 commit)

**2. [Rule 1 - Bug] Fixed optional fields assertion to use DOM not DB query**
- **Found during:** Task 2 (system tests)
- **Issue:** Plan template used `Medication.find_by(name:, user:)` directly in the test thread, which returned nil because the DB record was created in the Puma server thread (separate DB connection in SQLite WAL + transactional tests).
- **Fix:** Changed assertion to navigate to index and verify the card renders "Sick-day dose" and "Doses per day" fields — tests the actual visible outcome.
- **Files modified:** test/system/medication_management_test.rb
- **Verification:** Test passes; optional fields confirmed rendered in card
- **Committed in:** fbbcd17 (Task 2 commit)

**3. [Rule 1 - Bug] Fixed remove test to use custom confirm dialog instead of accept_confirm**
- **Found during:** Task 2 (system tests)
- **Issue:** Plan used `accept_confirm` for the Remove confirmation, but the app uses `confirm_controller.js` which renders a `<dialog>` modal. `accept_confirm` only handles native `window.confirm` dialogs.
- **Fix:** Added `confirm_dialog` helper method that clicks `dialog.confirm-dialog button[data-action='confirm#accept']`. Used this helper in the remove test.
- **Files modified:** test/system/medication_management_test.rb
- **Verification:** Remove test passes; medication disappears from DOM
- **Committed in:** fbbcd17 (Task 2 commit)

---

**Total deviations:** 3 auto-fixed (all Rule 1 - Bug)
**Impact on plan:** All fixes necessary for tests to pass against the actual app behaviour. No scope creep.

## Issues Encountered
None beyond the three bugs documented above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 11 complete: all success criteria met
  1. Medication list at /settings/medications with empty-state prompt
  2. Optional fields visible and saved correctly
  3. Inline edit via Turbo Frame updates card immediately
  4. Delete removes medication; cross-user isolation enforced (404)
- 256 tests passing, no regressions
- Ready for Phase 12 (Medication CSS styling or next milestone feature)

## Self-Check: PASSED

- test/controllers/settings/medications_controller_test.rb: FOUND
- test/system/medication_management_test.rb: FOUND
- .ariadna_planning/phases/11-medication-management-ui/11-03-SUMMARY.md: FOUND
- Commit 8fa710e: FOUND
- Commit fbbcd17: FOUND

---
*Phase: 11-medication-management-ui*
*Completed: 2026-03-08*
