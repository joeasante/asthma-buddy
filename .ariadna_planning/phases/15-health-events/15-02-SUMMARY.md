---
phase: 15-health-events
plan: "02"
subsystem: testing
tags: [capybara, selenium, minitest, system-tests, rails, turbo-streams, stimulus]

# Dependency graph
requires:
  - phase: 15-01
    provides: HealthEvent model, controller, views, fixtures (alice_gp_appointment, alice_illness_ongoing, alice_illness_resolved, alice_medication_change, bob_hospital)

provides:
  - 11 system tests covering full Medical History UI in headless Chrome
  - CRUD flows (add illness, add GP appointment, edit, delete with custom dialog)
  - Display assertions (point-in-time single datetime, date range, Ongoing badge)
  - Auth guard and cross-user URL isolation assertions
  - Dashboard chart marker integration assertion

affects:
  - 15-03 (subsequent Medical History plans can reference system test patterns)
  - any phase integrating health events into other views

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "CSS text-transform:uppercase badge assertions use case-insensitive regex: assert_text(/label/i)"
    - "Custom confirm_controller dialog tested via: find('dialog.confirm-dialog button[data-action=confirm#accept]').click"
    - "Toast flash assertions use assert_text on toast-message span injected by toast_controller.js"
    - "Turbo Stream delete assert_no_selector fires after confirm_dialog without wait: argument needed"

key-files:
  created:
    - test/system/medical_history_test.rb
  modified: []

key-decisions:
  - "CSS text-transform:uppercase makes badge text visible as uppercase — assert_text case-sensitive fails; use regex with /i flag"
  - "Edit page h1 is 'Edit medical event' (not 'Edit event' as plan specified) — test uses actual template text"
  - "Pre-commit hook added chart marker integration test (test 11) checking canvas data-chart-health-events-value attribute"
  - "delete flash comes via toast_controller.js injecting span.toast-message — assert_text works on dynamically injected text"

patterns-established:
  - "Case-insensitive badge assertion: assert_text(/badge-label/i) pattern for all event-badge assertions"
  - "confirm_dialog helper method: find('dialog.confirm-dialog button[data-action=confirm#accept]').click"

requirements_covered:
  - id: "EVT-01"
    description: "User can add health events"
    evidence: "test/system/medical_history_test.rb — add illness + add GP appointment tests"
  - id: "EVT-02"
    description: "User can edit and delete health events"
    evidence: "test/system/medical_history_test.rb — edit event + delete event tests"
  - id: "EVT-03"
    description: "Point-in-time vs duration event display"
    evidence: "test/system/medical_history_test.rb — display assertion tests (single time, date range, ongoing badge)"

# Metrics
duration: 12min
completed: 2026-03-09
---

# Phase 15 Plan 02: Medical History System Tests Summary

**11 Capybara/Selenium system tests verifying the full Medical History UI — CRUD flows, point-in-time vs duration display, custom confirm dialog, auth guard, and cross-user isolation all passing in headless Chrome.**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-03-09T15:31:00Z
- **Completed:** 2026-03-09T15:43:39Z
- **Tasks:** 1 (single task plan)
- **Files modified:** 1

## Accomplishments

- 11 system tests covering the complete Medical History feature UI in headless Chrome
- All 4 initially failing tests fixed (CSS text-transform uppercase mismatch, edit page h1 text)
- Pre-commit hook added dashboard chart marker integration test which also passes
- Confirmed custom confirm_controller.js dialog works with Capybara (not native browser confirm)
- Verified Turbo Stream delete removes DOM element and toast flash appears

## Requirements Covered

| REQ-ID | Requirement | Evidence |
|--------|-------------|----------|
| EVT-01 | User can add health events | add illness event + add GP appointment tests |
| EVT-02 | User can edit and delete health events | edit event + delete with confirm dialog tests |
| EVT-03 | Point-in-time vs duration event display | 3 display assertion tests (single time, date range, ongoing badge) |

## Task Commits

1. **Task 1: System tests — CRUD flows and auth** - `53d2ac6` (feat)

**Plan metadata:** (created in this summary commit)

## Files Created/Modified

- `test/system/medical_history_test.rb` — 11 system tests, 214 lines, 37 assertions

## Decisions Made

- **CSS text-transform uppercase mismatch:** Event badges rendered as "ILLNESS", "GP APPOINTMENT" etc. via CSS `text-transform: uppercase`. Capybara's `assert_text` checks visible rendered text. Fixed by using case-insensitive regex: `assert_text(/illness/i)` and `assert_selector ".event-ongoing-badge", text: /ongoing/i`.
- **Edit page h1:** Plan specified `"Edit event"` but actual template has `"Edit medical event"` — test uses the actual template text.
- **Pre-commit hook addition:** Hook added a test `"health event markers appear in dashboard chart section"` which checks `canvas[data-chart-health-events-value]` attribute contains the event's date. This test also passes.
- **Toast flash vs inline flash:** Delete uses Turbo Stream with toast_controller.js injecting `<span class="toast-message">` into `#toast-region`. `assert_text "Medical event deleted."` works because Capybara checks full visible DOM including dynamically injected content.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed case-sensitive badge text assertions breaking on CSS text-transform:uppercase**
- **Found during:** Task 1 (running tests)
- **Issue:** `assert_text "Illness"` failed because CSS `text-transform: uppercase` causes Capybara to see "ILLNESS" as visible text. Same for "GP appointment" -> "GP APPOINTMENT" and "Other" -> "OTHER". `.event-ongoing-badge` text "Ongoing" rendered as "ONGOING".
- **Fix:** Changed string assertions to case-insensitive regex: `assert_text(/illness/i)`, `assert_text(/gp appointment/i)`, `assert_text(/other/i)`, `assert_selector ".event-ongoing-badge", text: /ongoing/i`
- **Files modified:** `test/system/medical_history_test.rb`
- **Verification:** All 4 previously failing tests now pass
- **Committed in:** `53d2ac6` (Task 1 commit, via hook)

**2. [Rule 1 - Bug] Corrected edit page h1 assertion from plan**
- **Found during:** Task 1 (reading actual template)
- **Issue:** Plan specified `assert_selector "h1", text: "Edit event"` but `edit.html.erb` has `<h1>Edit medical event</h1>`
- **Fix:** Changed assertion to `assert_selector "h1", text: "Edit medical event"`
- **Files modified:** `test/system/medical_history_test.rb`
- **Verification:** Edit test passes
- **Committed in:** `53d2ac6`

---

**Total deviations:** 2 auto-fixed (both Rule 1 — bug corrections)
**Impact on plan:** Both fixes ensure tests correctly verify the actual UI. No scope creep.

## Issues Encountered

- First test run after `db:migrate` gave `NameError: undefined local variable or method 'health_events_url'` for all tests — caused by test DB schema being out of sync. Fixed by running `bin/rails db:test:prepare`. This is a standard Rails workflow issue when migrations are pending in development.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- System tests fully green (11/11) for the Medical History feature
- Complete coverage: CRUD, display variants, auth, cross-user isolation, chart integration
- Ready for Phase 15 Plan 03 (any remaining health events work) or next milestone

---
*Phase: 15-health-events*
*Completed: 2026-03-09*
