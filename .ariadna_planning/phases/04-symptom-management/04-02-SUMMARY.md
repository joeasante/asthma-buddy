---
phase: 04-symptom-management
plan: 02
subsystem: testing
tags: [rails, minitest, capybara, system-tests, turbo-frame, turbo-stream, authorization]

# Dependency graph
requires:
  - phase: 04-01
    provides: edit/update/destroy actions on SymptomLogsController, Turbo Frame inline edit, Turbo Stream destroy
provides:
  - Controller tests: edit/update/destroy with ownership enforcement and cross-user 404 checks (already present from 04-01)
  - System tests: inline edit flow, delete flow, cross-user URL isolation
affects: [04-symptom-management-complete, phase-5-timeline]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - accept_confirm wraps button_to click to accept browser confirm dialog for data-turbo-confirm
    - within("##{dom_id(entry)}") scopes Capybara interactions to the turbo-frame of a specific entry
    - button_to renders as <form> element — use specific input/select selectors not bare "form" to assert edit form absence
    - assert_no_selector "form input[name='symptom_log[symptom_type]']" reliably distinguishes edit form from button_to form
    - Cross-user 404 in system test: assert edit form inputs absent rather than assert URL change (Rails error page stays at same URL)

key-files:
  created: []
  modified:
    - test/system/symptom_logging_test.rb

key-decisions:
  - "button_to renders a <form> — cannot use assert_no_selector 'form' after update; use select name selector to distinguish edit form from delete button form"
  - "Cross-user 404 system test: Rails error page stays at same URL in test env, so assert the edit form inputs are absent not assert_no_current_path"
  - "Controller tests for edit/update/destroy were already added in Plan 01 as a deviation — Task 1 verified complete without new commits needed"

patterns-established:
  - "System test scoping with within(dom_id) for turbo-frame targeted interactions"
  - "accept_confirm API for Capybara browser dialog acceptance on data-turbo-confirm buttons"

# Metrics
duration: 8min
completed: 2026-03-07
---

# Phase 4 Plan 02: Symptom Log Edit/Delete Test Coverage Summary

**Minitest coverage for edit, update, and destroy actions — controller tests verified complete from Plan 01 deviation; 3 new system tests added covering inline edit, delete flow, and cross-user URL isolation, with 77 total tests passing.**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-03-07
- **Completed:** 2026-03-07
- **Tasks:** 2 (Task 1: verified complete; Task 2: 3 new system tests)
- **Files modified:** 1 (test/system/symptom_logging_test.rb)

## Accomplishments

- Verified all 8 controller tests for edit/update/destroy (including cross-user 404) were already present from Plan 01 deviation — 16 controller tests passing
- Added 3 new system tests: inline edit flow via Turbo Frame, delete flow via confirm dialog, cross-user URL isolation (404 error page)
- Fixed assertion approach: `button_to` renders as `<form>` so assertion uses specific input name selectors
- Fixed cross-user isolation assertion: Rails error page stays at same URL — assert edit form inputs absent instead of path change
- Full test suite: 77 total tests (64 unit/integration + 9 system + 4 others), 0 failures

## Task Commits

Each task committed atomically:

1. **Task 1: Controller tests for edit/update/destroy** - already committed as `54cb6ce` in Plan 01 (deviation — no new commit needed)
2. **Task 2: System tests for inline edit, delete, and cross-user isolation** - `c402ac4` (test)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `test/system/symptom_logging_test.rb` - Added 3 system tests: inline edit flow, delete flow, cross-user URL isolation

## Decisions Made

- **button_to renders as form:** Rails `button_to` helper wraps its button in a `<form>` tag. After a Turbo Stream update replaces an entry with the display partial (which includes a Delete button_to), `assert_no_selector "form"` fails because the button_to's wrapper form is present. Fixed by using `assert_no_selector "input, select[name='symptom_log[symptom_type]']"` to specifically check that edit form inputs are gone.

- **Cross-user 404 stays at same URL:** Rails error pages (including RecordNotFound 404) do not redirect — the URL remains the edit path while displaying the error. `assert_no_current_path` therefore fails since path equals path. Fixed by asserting the edit form inputs (specifically `form input[name='symptom_log[symptom_type]']`) are absent from the page, which correctly validates the user cannot see or interact with the edit form.

- **Controller tests already complete:** Plan 04-01 added 9 controller tests as a deviation (Rule 2 - Missing Critical) covering all edit/update/destroy scenarios. Plan 04-02 Task 1 was therefore complete before execution started. The existing tests were verified passing and no duplication was introduced.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed assert_no_selector "form" failing due to button_to rendering**
- **Found during:** Task 2 (system test inline edit flow)
- **Issue:** After a Turbo Stream update, the entry partial is re-rendered showing the Delete button. `button_to` renders as `<form action="..." method="post">`, so `assert_no_selector "form"` incorrectly fails because the delete form is present even though the edit form is gone
- **Fix:** Changed to `assert_no_selector "input, select[name='symptom_log[symptom_type]']"` — specifically targets edit form inputs, not all forms
- **Files modified:** `test/system/symptom_logging_test.rb`
- **Commit:** `c402ac4`

**2. [Rule 1 - Bug] Fixed cross-user URL isolation assertion for Rails error pages**
- **Found during:** Task 2 (system test cross-user URL isolation)
- **Issue:** `assert_no_current_path edit_symptom_log_path(bob_entry)` fails because Rails renders 404 error page at the same URL — the path doesn't change
- **Fix:** Changed to `assert_no_selector "form input[name='symptom_log[symptom_type]']"` — verifies the edit form is not shown regardless of what page is displayed
- **Files modified:** `test/system/symptom_logging_test.rb`
- **Commit:** `c402ac4`

---

**Total deviations:** 2 auto-fixed (Rule 1 bugs in test assertions) + 1 pre-completed task (controller tests from Plan 01)
**Impact on plan:** All fixes necessary for correct test behavior. No scope creep.

## Issues Encountered

None beyond the auto-fixed assertion bugs above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- All edit/delete flows fully tested at both controller and system test levels
- 77 total tests passing (0 failures, 0 errors, 0 skips)
- Phase 4 requirements SYMP-05 and SYMP-06 verified by complete test suite
- Ready for Phase 5 (Timeline/History view)

---
*Phase: 04-symptom-management*
*Completed: 2026-03-07*

## Self-Check: PASSED

All artifacts verified:
- test/system/symptom_logging_test.rb - FOUND
- test/controllers/symptom_logs_controller_test.rb - FOUND
- .ariadna_planning/phases/04-symptom-management/04-02-SUMMARY.md - FOUND
- Commit c402ac4 - FOUND
