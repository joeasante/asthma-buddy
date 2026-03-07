---
phase: 07-peak-flow-display
plan: 04
subsystem: testing
tags: [rails, minitest, capybara, system-tests, turbo-frames, stimulus, zone-badges]

# Dependency graph
requires:
  - phase: 07-02
    provides: peak flow edit/update/destroy routes, inline Turbo Frame edit, custom Stimulus confirm dialog
  - phase: 07-01
    provides: zone badge CSS classes (.zone-badge--green, .zone-badge--yellow), readings index with preset filter

provides:
  - Browser-level system test coverage for peak flow zone badge rendering
  - End-to-end inline edit flow verification via Turbo Frame
  - Delete flow verification via custom Stimulus confirm dialog (.btn-confirm-delete)
  - Cross-user URL isolation test (alice cannot access bob's edit URL)
  - Validation error path test (HTML5 bypass → server-side Rails validation)

affects: [08-trend-analysis, 09-accessibility]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "assert_selector 'input[name=...]' inside within(turbo-frame) block — waits for frame navigation to complete before executing_script"
    - "execute_script after within block exits — ensures DOM mutations target fully-rendered frame content"
    - "find('input[name=...]').set(value) over fill_in for number fields when bypassing browser validation"
    - "Custom Stimulus confirm dialog: click Delete → find('.btn-confirm-delete', wait: 5).click"

key-files:
  created:
    - test/system/peak_flow_display_test.rb
  modified: []

key-decisions:
  - "execute_script to strip HTML5 validation attrs must run after within block asserts the target input is present — prevents race condition where script runs before Turbo Frame loads edit form"
  - "submit value 0 (not blank) for validation error test — blank string in number field triggers browser 'Please fill in this field' even without required; 0 passes to server and fails greater_than: 0 Rails validation"
  - "assert_current_path peak_flow_readings_url(preset: 'all') for validation test — URL retains preset param since we visited with preset=all"
  - "Custom Stimulus confirm dialog (dialog.showModal()) not intercepted by Capybara accept_confirm — click .btn-confirm-delete directly"

patterns-established:
  - "Turbo Frame + execute_script: assert the target input field exists inside within() before exiting the block, then run execute_script globally — guarantees script targets fully-rendered frame DOM"

requirements_covered: []

# Metrics
duration: 12min
completed: 2026-03-07
---

# Phase 7 Plan 04: Peak Flow Display System Tests Summary

**7 browser system tests covering zone badge rendering, inline Turbo Frame edit, custom Stimulus confirm delete, and cross-user URL isolation for the peak flow readings index**

## Performance

- **Duration:** 12 min
- **Started:** 2026-03-07T20:25:00Z
- **Completed:** 2026-03-07T20:37:00Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- 7 passing system tests for peak flow display: green badge, yellow badge, user data isolation, inline edit (form → update → zone badge), validation error (server-side), delete (custom Stimulus dialog), cross-user edit URL 404
- Identified and resolved two test correctness issues: URL preset param in assert_current_path, and HTML5 browser validation race condition with execute_script timing
- Confirmed custom Stimulus confirm controller (dialog.showModal()) requires direct `.btn-confirm-delete` click rather than Capybara `accept_confirm`

## Task Commits

Each task was committed atomically:

1. **Task 1: System tests for zone badges, edit flow, delete flow, cross-user isolation** - `51ca0c9` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified
- `test/system/peak_flow_display_test.rb` — 7 system tests: zone badge CSS class assertions, inline edit Turbo Frame flow, validation error via HTML5 bypass, delete via custom Stimulus dialog, cross-user URL isolation

## Decisions Made
- `execute_script` to strip HTML5 validation attributes (`required`, `min`, `max`) must run AFTER `assert_selector "input[name='peak_flow_reading[value]']"` inside the `within` block — this ensures Turbo Frame has loaded the edit form into the DOM before the script runs. Without this ordering, the script runs against stale DOM and the browser still has `min="1"` on the input.
- Use `find("input[name='peak_flow_reading[value]']").set("0")` to submit value 0 (not blank "") for the validation error test — a blank number field triggers the browser's native "Please fill in this field" tooltip even after removing `required`, because the field type is `number` and Chrome enforces a non-empty constraint separately. Value 0 bypasses this, reaches the server, and fails Rails' `greater_than: 0` validation.
- `assert_current_path peak_flow_readings_url(preset: "all")` not `peak_flow_readings_url` — visited with `?preset=all` query param which is preserved in the URL after the Turbo Stream response.
- Delete flow uses `find(".btn-confirm-delete", wait: 5).click` — the custom Stimulus controller calls `dialog.showModal()` which is NOT intercepted by Capybara's `accept_confirm`. The `.btn-confirm-delete` button is in the layout's `<dialog>` element and calls `confirm#accept`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed assert_current_path to include preset query parameter**
- **Found during:** Task 1 (validation error test)
- **Issue:** Test asserted `peak_flow_readings_url` but page URL was `peak_flow_readings_url(preset: "all")` since we navigated with that param
- **Fix:** Changed assertion to `assert_current_path peak_flow_readings_url(preset: "all")`
- **Files modified:** test/system/peak_flow_display_test.rb
- **Verification:** Test passed after fix
- **Committed in:** 51ca0c9 (Task 1 commit)

**2. [Rule 1 - Bug] Fixed HTML5 validation bypass race condition and blank-vs-zero strategy**
- **Found during:** Task 1 (validation error test)
- **Issue:** `execute_script` ran before Turbo Frame loaded edit form, so `min="1"` was still present when form submitted. Additionally, blank value in number field triggered browser "Please fill in this field" not Rails validation.
- **Fix:** (a) Moved `assert_selector "input[name='peak_flow_reading[value]']"` inside `within` block BEFORE `execute_script` call outside block. (b) Changed test value from `""` to `"0"` which passes browser constraints but fails Rails `greater_than: 0` validation.
- **Files modified:** test/system/peak_flow_display_test.rb
- **Verification:** Test passed with multiple seeds (19059, 45789)
- **Committed in:** 51ca0c9 (Task 1 commit)

---

**Total deviations:** 2 auto-fixed (2 Rule 1 bugs)
**Impact on plan:** Both auto-fixes required for test correctness. No scope creep.

## Issues Encountered
- Pre-existing failure in `SymptomLoggingTest#test_user_can_delete_a_symptom_entry_and_it_disappears_from_the_list` (symptom_logging_test.rb:160) — uses `accept_confirm "Delete this entry?"` but the app uses a custom Stimulus dialog (dialog.showModal()) since Phase 6. This failure exists on the commit before 07-04 and is unrelated to this plan's changes.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 07 is fully complete: index with zone badges, date filter, inline edit/update/destroy with Turbo Stream, comprehensive controller tests (07-03), and browser system tests (07-04)
- Phase 08 (trend analysis) can proceed — peak flow readings model, zone calculation, and display layer are all verified end-to-end
- Pre-existing symptom logging delete system test failure (accept_confirm vs custom dialog) should be fixed when capacity allows

---
*Phase: 07-peak-flow-display*
*Completed: 2026-03-07*
