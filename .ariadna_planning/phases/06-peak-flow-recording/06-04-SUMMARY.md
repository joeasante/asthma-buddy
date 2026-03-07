---
phase: 06-peak-flow-recording
plan: 04
subsystem: testing
tags: [rails, minitest, capybara, system-tests, integration-tests, peak-flow, settings]

# Dependency graph
requires:
  - phase: 06-02
    provides: SettingsController, settings_path, settings_personal_best_path, PersonalBestRecord with current_for
  - phase: 06-03
    provides: PeakFlowReadingsController (new + create), zone_flash_message, peak_flow_reading form with banner and zone feedback

provides:
  - Controller integration tests for PeakFlowReadingsController (new, create — 9 tests)
  - Controller integration tests for SettingsController (show, update_personal_best — 10 tests)
  - System test covering full peak flow recording flow with zone feedback (5 scenarios)

affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "System test sign_in_as uses form-based login (consistent with Phase 3/5 pattern) — defined as local helper method"
    - "Controller tests use sign_in_as from SessionTestHelper (cookie-based, only for ActionDispatch::IntegrationTest)"
    - "assert_no_css / assert_css used for banner visibility checks in system tests"

key-files:
  created:
    - test/controllers/peak_flow_readings_controller_test.rb
    - test/controllers/settings_controller_test.rb
    - test/system/peak_flow_recording_test.rb
  modified: []

key-decisions:
  - "System test sign_in_as defined as local helper using form-based login — ApplicationSystemTestCase does not include SessionTestHelper (which is ActionDispatch::IntegrationTest-only)"
  - "assert_text 'No personal best set' matches actual view text 'No personal best set yet.' via partial match"
  - "HTML5 required attribute removed via execute_script before blank-submit system test — prevents browser-native validation blocking server-side validation path"

patterns-established:
  - "Peak flow controller test pattern: PersonalBestRecord.where(user:).delete_all to set up no-PB state"
  - "System test local sign_in_as: visit new_session_url, fill fields, click_button 'Sign in', assert_current_path root_url"

requirements_covered:
  - id: "PEAK-01"
    description: "A logged-in user can record a peak flow reading via the entry form"
    evidence: "test/controllers/peak_flow_readings_controller_test.rb, test/system/peak_flow_recording_test.rb"
  - id: "PEAK-02"
    description: "A logged-in user can set their personal best in settings"
    evidence: "test/controllers/settings_controller_test.rb, test/system/peak_flow_recording_test.rb"
  - id: "PEAK-03"
    description: "Zone is computed and appears in the flash message after saving"
    evidence: "test/controllers/peak_flow_readings_controller_test.rb (Green Zone flash assertion), test/system/peak_flow_recording_test.rb (Green Zone text visible)"

# Metrics
duration: 3min
completed: 2026-03-07
---

# Phase 6 Plan 04: Tests Summary

**19 controller integration tests + 5 system tests covering peak flow recording, settings personal best, zone flash, multi-user isolation, and unauthenticated access — full suite 142 tests, 0 failures.**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-07T16:33:52Z
- **Completed:** 2026-03-07T16:36:40Z
- **Tasks:** 2
- **Files modified:** 3 created

## Accomplishments

- `PeakFlowReadingsControllerTest`: 9 tests — new form render, banner visibility (with/without PB), create happy path with Green Zone flash, no-PB flash message, 422 on missing value/recorded_at, user isolation (readings always scoped to authenticated user), unauthenticated redirects for new and create
- `SettingsControllerTest`: 10 tests — show renders with correct h1, displays current PB value, shows unset state (`.settings-pb-unset`), update_personal_best creates record + redirects with "L/min" notice, validation failures for value < 100, > 900, and blank, unauthenticated redirect, user isolation on create
- `PeakFlowRecordingTest` (system): 5 scenarios — full recording flow with Green Zone flash and form reset, banner when no PB, no-PB flash on create, validation error for blank value (HTML5 required stripped via JS), settings-to-form flow (set PB then banner disappears)
- Full test suite: 142 tests, 409 assertions, 0 failures, 0 errors, 0 skips

## Requirements Covered

| REQ-ID | Requirement | Evidence |
|--------|-------------|----------|
| PEAK-01 | User can record a peak flow reading | controller + system test (happy path, zone flash) |
| PEAK-02 | User can set personal best in settings | settings controller test + settings-to-form system test |
| PEAK-03 | Zone auto-calculated and shown in flash | Green Zone flash assertion (controller + system), no-PB flash (controller + system) |

## Task Commits

Each task was committed atomically:

1. **Task 1: PeakFlowReadingsController and SettingsController integration tests** - `054b8b6` (test)
2. **Task 2: System test for full peak flow recording flow** - `6845fa7` (test)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `test/controllers/peak_flow_readings_controller_test.rb` — 9 integration tests for new/create; covers render, banner, zone flash, no-PB flash, 422 validation, isolation, unauthenticated
- `test/controllers/settings_controller_test.rb` — 10 integration tests for show/update_personal_best; covers render, current PB display, unset state, happy path, validation failures, unauthenticated, isolation
- `test/system/peak_flow_recording_test.rb` — 5 Capybara system tests; local sign_in_as helper; covers full recording flow with zone feedback, banner visibility, no-PB flash, blank-value error, settings→form integration

## Decisions Made

- `sign_in_as` defined as local helper in system test using form-based login — `SessionTestHelper` only loads for `ActionDispatch::IntegrationTest`, not `ApplicationSystemTestCase`. Consistent with Phase 3/5 system test pattern.
- System test for blank-value validation uses `execute_script` to remove HTML5 `required` attribute before submit — without this, browser-native validation blocks the request before reaching the server.
- `assert_text "No personal best set"` matches the actual view text "No personal best set yet." via Capybara partial text match.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 6 PEAK-01, PEAK-02, PEAK-03 requirements demonstrably satisfied by test outcomes
- Phase 6 is now ship-ready: models (06-01), settings (06-02), entry form (06-03), and tests (06-04) all complete
- Phase 7 (peak flow history/timeline) can proceed — test infrastructure for peak flow recordings is in place

---
*Phase: 06-peak-flow-recording*
*Completed: 2026-03-07*

## Self-Check: PASSED

| Check | Result |
|-------|--------|
| test/controllers/peak_flow_readings_controller_test.rb | FOUND |
| test/controllers/settings_controller_test.rb | FOUND |
| test/system/peak_flow_recording_test.rb | FOUND |
| 06-04-SUMMARY.md | FOUND |
| Commit 054b8b6 (Task 1) | FOUND |
| Commit 6845fa7 (Task 2) | FOUND |
