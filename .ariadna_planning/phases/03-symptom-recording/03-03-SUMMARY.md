---
phase: 03-symptom-recording
plan: 03
subsystem: testing
tags: [rails, capybara, selenium, system-tests, turbo-streams, lexxy, multi-user-isolation]

# Dependency graph
requires:
  - phase: 03-01
    provides: SymptomLog model, has_rich_text :notes, enums, fixtures
  - phase: 03-02
    provides: SymptomLogsController, views, Turbo Stream response, sign_in_as helper
provides:
  - 6 system tests verifying full symptom logging UX in a real browser
  - Turbo Stream prepend verified end-to-end (entry appears without page refresh)
  - Multi-user isolation verified at browser level (alice cannot see bob's entries)
  - Lexxy editor interaction pattern established for system tests
affects: [phase-4-edit-delete, phase-9-accessibility]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Lexxy editor interaction: find('lexxy-editor [data-lexical-editor]', wait: 10).click + send_keys"
    - "execute_script to strip HTML5 required attributes before blank-form submission tests"
    - "DOM id isolation check: assert_no_selector '##{dom_id(record)}' for multi-user tests"

key-files:
  created:
    - test/system/symptom_logging_test.rb
  modified:
    - config/importmap.rb
    - app/javascript/application.js

key-decisions:
  - "Lexxy editor targeted via 'lexxy-editor [data-lexical-editor]' — the contenteditable div Lexical renders inside the custom element"
  - "Removed @rails/actiontext import — Lexxy handles the editor; ActionText backend (has_rich_text) needs no JS module"
  - "execute_script strips HTML5 required before blank-form test so browser validation doesn't swallow the submit before Rails sees it"
  - "Isolation test creates bob's record directly (bypasses controller) then asserts dom_id is absent for alice — definitive proof of user-scoped queries"

# Metrics
duration: ~15min
completed: 2026-03-07
---

# Phase 3 Plan 03: Symptom Logging System Tests Summary

**6 system tests verify the complete symptom logging flow end-to-end in Chrome — Turbo Stream prepend, form clearing, Lexxy notes, inline validation, and multi-user isolation all confirmed at the browser level**

## Performance

- **Duration:** ~15 min
- **Completed:** 2026-03-07
- **Tasks:** 1 of 1
- **Files modified:** 3

## Accomplishments

- Created `test/system/symptom_logging_test.rb` with 6 Capybara/Selenium tests covering:
  1. Logged-in user logs a symptom — entry appears in list without page refresh (Turbo Stream verified)
  2. Form clears after successful submission (fresh blank form ready immediately)
  3. Notes entered in Lexxy editor are saved and appear in the entry list
  4. Validation errors appear inline without leaving the page (422 + Turbo Stream error path)
  5. Multi-user isolation — Alice cannot see Bob's entries (dom_id assertion)
  6. Unauthenticated redirect to sign in
- Corrected Lexxy editor interaction: `find("lexxy-editor [data-lexical-editor]", wait: 10)` targets the Lexical contenteditable div inside the custom element
- Removed `@rails/actiontext` from importmap and application.js — Lexxy handles the editor frontend; ActionText storage backend requires no JS import

## Task Commits

1. **System tests + Lexxy-only cleanup** - `b7c0fdd` (feat)

## Files Created/Modified

- `test/system/symptom_logging_test.rb` — 6 system tests (10 runs, 47 assertions)
- `config/importmap.rb` — removed `@rails/actiontext` pin
- `app/javascript/application.js` — removed `import "@rails/actiontext"`

## Decisions Made

- `lexxy-editor [data-lexical-editor]` is the correct selector — Lexxy's `<lexxy-editor>` custom element wraps a Lexical `contenteditable` div with `data-lexical-editor` attribute; the outer custom element is not directly interactable
- `execute_script` removes HTML5 `required` attributes before the blank-form submit test — browser-native validation would prevent the form from reaching the server, so the test would never exercise the Rails validation path
- `@rails/actiontext` removed — Lexxy imports `@rails/activestorage` directly for file attachment handling; the actiontext.esm.js module only served to initialise Trix

## Deviations from Plan

- Plan specified `find("trix-editor")` — corrected to `find("lexxy-editor [data-lexical-editor]")` since the project uses Lexxy, not Trix

## Issues Encountered

- Initial `find("lexxy-editor")` raised `ElementNotInteractableError` — Lexxy's outer custom element is not directly interactable; fixed by targeting the inner `[data-lexical-editor]` contenteditable div

## Next Phase Readiness

- All Phase 3 must-haves verified by system tests
- Lexxy interaction pattern documented for Phase 4+ system tests
- 10 system test runs, 47 assertions, 0 failures — full suite green

---
*Phase: 03-symptom-recording*
*Completed: 2026-03-07*

## Self-Check: PASSED

- test/system/symptom_logging_test.rb: FOUND
- config/importmap.rb: FOUND (no @rails/actiontext)
- app/javascript/application.js: FOUND (no @rails/actiontext)
- Commit b7c0fdd: FOUND
