---
phase: 01-foundation
plan: 03
subsystem: testing
tags: [minitest, capybara, selenium, headless-chrome, system-tests, integration-tests]

requires:
  - phase: 01-foundation plan 02
    provides: HomeController#index and application layout with semantic HTML5 structure

provides:
  - Minitest baseline with 3 integration tests and 1 system test all passing (green)
  - HomeController integration tests covering 200 response, layout structure, and page title
  - System test infrastructure with Capybara + headless Chrome
  - Homepage system test asserting h1, header, and nav render correctly

affects: [all future phases that add tests]

tech-stack:
  added: []
  patterns: [ActionDispatch::IntegrationTest for controller tests, ApplicationSystemTestCase with headless Chrome for system tests]

key-files:
  created:
    - test/controllers/home_controller_test.rb
    - test/application_system_test_case.rb
    - test/system/home_test.rb
  modified: []

key-decisions:
  - "application_system_test_case.rb placed in test/ (not test/system/) — Rails load path convention"
  - "Headless Chrome used for system tests (screen size 1400x1400)"

patterns-established:
  - "Integration tests inherit ActionDispatch::IntegrationTest, live in test/controllers/"
  - "System tests inherit ApplicationSystemTestCase, live in test/system/"
  - "application_system_test_case.rb lives in test/ (not test/system/) to be on load path"

requirements_covered: []

duration: 10min
completed: 2026-03-06
---

# Plan 01-03: Test Baseline Summary

**Minitest baseline established — 3 integration tests (GET /, layout structure, page title) and 1 headless Chrome system test, all passing green**

## Performance

- **Duration:** ~10 min
- **Completed:** 2026-03-06
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- HomeController integration tests: GET / returns 200, layout has header/main/footer landmark roles, title includes "Asthma Buddy"
- System test base class with Capybara + Selenium headless Chrome (1400×1400)
- Homepage system test asserting h1, header, and nav presence
- `bin/rails test` exits 0 (3 runs, 9 assertions, 0 failures)
- `bin/rails test:system` exits 0 (1 run, 3 assertions, 0 failures)

## Task Commits

1. **Task 1: HomeController integration tests** — `df02055` (feat)
2. **Task 2: System test infrastructure + homepage system test** — `ded67b4` (feat)

## Files Created/Modified
- `test/controllers/home_controller_test.rb` — 3 integration tests for root path
- `test/application_system_test_case.rb` — system test base with headless Chrome driver
- `test/system/home_test.rb` — homepage system test (h1, header, nav)

## Decisions Made
- `application_system_test_case.rb` moved from `test/system/` to `test/` — required by Rails load path so `require "application_system_test_case"` resolves correctly

## Deviations from Plan
None — plan executed exactly as written, with one fix: file placement corrected to follow Rails convention.

## Issues Encountered
- Initial placement of `application_system_test_case.rb` in `test/system/` caused `LoadError: cannot load such file -- application_system_test_case`. Fixed by moving to `test/` (standard Rails location).

## Next Phase Readiness
- Green test baseline established. All future plans can run `bin/rails test` and rely on 0 failures as a baseline.
- Phase 2 (authentication) will extend this baseline with auth-related tests.

---
*Phase: 01-foundation*
*Completed: 2026-03-06*
