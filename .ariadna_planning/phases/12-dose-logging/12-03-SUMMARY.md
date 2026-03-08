---
phase: 12-dose-logging
plan: 03
subsystem: testing
tags: [rails, minitest, capybara, turbo-streams, dose-logging, system-tests, integration-tests]

# Dependency graph
requires:
  - phase: 12-dose-logging/12-01
    provides: DoseLogsController (create, destroy), nested routes under settings/medications
  - phase: 12-dose-logging/12-02
    provides: dose log form partial, dose history section, Turbo Stream view files, remaining_count element

provides:
  - Controller integration tests for DoseLogsController (create + destroy, 11 tests)
  - System tests for dose logging and deletion flows (5 tests)
  - layouts/_flash partial extracted from application layout (required by dose log Turbo Stream views)
  - Turbo Stream view fix: dose_history and remaining_count wrappers preserved after replace

affects: [12-dose-logging, future testing phases]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Controller test cross-user isolation: POST to another user's medication returns 404 (set_medication scopes via Current.user)"
    - "Turbo Stream replace must re-render the container element with its ID, not just inner content"
    - "System tests assert post-stream DOM state via fresh within selectors (not within after turbo_stream.replace)"

key-files:
  created:
    - test/controllers/settings/dose_logs_controller_test.rb
    - test/system/dose_logging_test.rb
    - app/views/layouts/_flash.html.erb
  modified:
    - app/views/layouts/application.html.erb
    - app/views/settings/dose_logs/create.turbo_stream.erb
    - app/views/settings/dose_logs/destroy.turbo_stream.erb

key-decisions:
  - "turbo_stream.replace replaces the entire element including its tag; replacement block must re-render the container element with the same ID to preserve DOM references"
  - "layouts/_flash partial extracted from application.html.erb so Turbo Stream responses can render the flash div with dynamic flash.now values"
  - "System tests use confirm_dialog helper (clicks dialog.confirm-dialog button[data-action='confirm#accept']) — same pattern as medication_management_test.rb"

patterns-established:
  - "Turbo Stream wrapper preservation: when replacing dose_history_NNN or remaining_count_NNN, always include the outer div/dd element with its ID in the replacement block"

requirements_covered:
  - id: "DOSE-01"
    description: "User can log a dose from the medication card and see it appear in dose history"
    evidence: "test/system/dose_logging_test.rb#test_user_can_log_a_dose_from_the_medication_card_and_it_appears_in_dose_history"
  - id: "DOSE-02"
    description: "User can delete a dose log entry and remaining count updates"
    evidence: "test/system/dose_logging_test.rb#test_user_can_delete_a_dose_log_entry_and_it_disappears_from_dose_history"

# Metrics
duration: 8min
completed: 2026-03-08
---

# Phase 12 Plan 03: Dose Logging Tests Summary

**Controller integration tests (11) and system tests (5) locking in DoseLogsController create/destroy, cross-user isolation, Turbo Stream media type contract, and dose history DOM update behaviour**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-03-08T17:42:37Z
- **Completed:** 2026-03-08T17:50:00Z
- **Tasks:** 2
- **Files modified:** 6 (2 test files created, 1 partial created, 3 views modified)

## Accomplishments

- Controller test file (106 lines, 11 tests) covers create + destroy with Turbo Stream, cross-user 404 isolation, invalid params, and unauthenticated redirect
- System test file (138 lines, 5 tests) covers log dose flow, remaining count decrease, delete dose flow, remaining count increase, and unauthenticated redirect
- Fixed two latent bugs in Plan 12-02 Turbo Stream views (dose_history and remaining_count wrappers were dropped after replace)
- Created `layouts/_flash` partial — referenced by dose log Turbo Stream views but never created in Plan 12-02
- Full suite: 267 unit/integration tests, 0 failures, 0 errors

## Task Commits

Each task was committed atomically:

1. **Task 1: Controller integration tests for DoseLogsController** - `20b6855` (feat)
2. **Task 2: System tests for dose logging and deletion flows** - `2b26e3c` (feat)

**Plan metadata:** (included in Task 2 commit)

## Files Created/Modified

- `test/controllers/settings/dose_logs_controller_test.rb` - 11 controller integration tests for create, destroy, isolation
- `test/system/dose_logging_test.rb` - 5 system tests for log dose, delete dose, count updates, and auth
- `app/views/layouts/_flash.html.erb` - Flash partial extracted from application layout for Turbo Stream reuse
- `app/views/layouts/application.html.erb` - Updated to use `render "layouts/flash"` partial
- `app/views/settings/dose_logs/create.turbo_stream.erb` - Fixed: dose_history div and remaining_count dd now preserve IDs after replace
- `app/views/settings/dose_logs/destroy.turbo_stream.erb` - Same fix applied

## Decisions Made

- `turbo_stream.replace` replaces the entire matched element, not just its innerHTML — replacement block must include the container element with its `id` attribute to preserve DOM references for subsequent Turbo Stream targets and Capybara selectors
- `layouts/_flash` partial renders the `<div id="flash-messages">` wrapper with conditional notice/alert paragraphs — used in application layout and Turbo Stream views so flash HTML is consistent

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Missing `layouts/_flash` partial referenced by Turbo Stream views**
- **Found during:** Task 1 (running controller tests)
- **Issue:** `create.turbo_stream.erb` and `destroy.turbo_stream.erb` call `render "layouts/flash"` but the partial did not exist — causing `ActionView::Template::Error: Missing partial layouts/_flash` on any Turbo Stream response
- **Fix:** Created `app/views/layouts/_flash.html.erb` with the flash div markup; updated `application.html.erb` to use the partial
- **Files modified:** `app/views/layouts/_flash.html.erb` (created), `app/views/layouts/application.html.erb`
- **Verification:** Controller tests pass with `assert_equal "text/vnd.turbo-stream.html", response.media_type`
- **Committed in:** `20b6855` (Task 1 commit)

**2. [Rule 1 - Bug] Turbo Stream replace drops element IDs for `dose_history` and `remaining_count`**
- **Found during:** Task 2 (running system tests)
- **Issue:** `turbo_stream.replace "dose_history_NNN"` emitted a `<ul>` or `<p>` as the replacement — without the `<div id="dose_history_NNN">` wrapper. After the stream update, `#dose_history_NNN` no longer existed in the DOM. Same for `remaining_count_NNN` — the `<dd>` wrapper was dropped. System tests failed with `Capybara::ElementNotFound: Unable to find css "#dose_history_medication_NNN"`
- **Fix:** Wrapped the block content in `create.turbo_stream.erb` and `destroy.turbo_stream.erb` with the appropriate container elements (`<div id="dose_history_...">` and `<dd id="remaining_count_...">`)
- **Files modified:** `app/views/settings/dose_logs/create.turbo_stream.erb`, `app/views/settings/dose_logs/destroy.turbo_stream.erb`
- **Verification:** All 5 system tests pass; remaining count assertions succeed after stream updates
- **Committed in:** `2b26e3c` (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 1 — bugs in Plan 12-02 Turbo Stream views)
**Impact on plan:** Both fixes were necessary for correctness. Without them, the Turbo Stream responses either errored (bug 1) or silently corrupted the DOM (bug 2). No scope creep.

## Issues Encountered

None beyond the auto-fixed deviations above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 12 complete: DoseLog model, controller, views, and tests all delivered
- 267 unit/integration tests passing, 5 dose logging system tests passing
- Turbo Stream DOM ID preservation pattern now established for future stream-heavy features
- No blockers for Phase 13

## Self-Check: PASSED

- `test/controllers/settings/dose_logs_controller_test.rb` — FOUND (106 lines, min 80 required)
- `test/system/dose_logging_test.rb` — FOUND (138 lines, min 60 required)
- `app/views/layouts/_flash.html.erb` — FOUND
- Commit `20b6855` — FOUND
- Commit `2b26e3c` — FOUND
- `bin/rails test` — 267 tests, 0 failures, 0 errors (confirmed)
- All 5 dose logging system tests passing (confirmed)

---
*Phase: 12-dose-logging*
*Completed: 2026-03-08*
