---
phase: 03-symptom-recording
plan: 01
subsystem: database
tags: [rails, actiontext, trix, activerecord, sqlite, enums, validations]

# Dependency graph
requires:
  - phase: 02-authentication
    provides: User model with has_secure_password, sessions, and verified_user/unverified_user fixtures
provides:
  - symptom_logs table with integer enum columns, null constraints, user_id FK, composite index on [user_id, recorded_at]
  - SymptomLog model with 4-type symptom enum, 3-level severity enum (validate: true), presence validations, belongs_to :user, has_rich_text :notes, chronological scope
  - ActionText installed with active_storage and action_text migrations applied
  - 9 model tests covering valid records, presence validations, enum counts, rich text, and ordering
  - Fixtures (alice_wheezing, bob_coughing) for multi-user isolation tests in subsequent plans
affects: [03-02-controller, 03-03-views, 03-04-turbo-streams, 03-05-system-tests, phase-5-timeline]

# Tech tracking
tech-stack:
  added: [ActionText (Trix editor, Rails built-in), ActiveStorage (ActionText dependency)]
  patterns: [integer enums with validate: true for safe form handling, composite index user_id+recorded_at for timeline queries, dependent: :destroy for GDPR data ownership]

key-files:
  created:
    - db/migrate/20260306235435_create_symptom_logs.rb
    - app/models/symptom_log.rb
    - test/models/symptom_log_test.rb
    - test/fixtures/symptom_logs.yml
    - app/assets/stylesheets/actiontext.css
    - db/migrate/20260306235429_create_active_storage_tables.active_storage.rb
    - db/migrate/20260306235430_create_action_text_tables.action_text.rb
  modified:
    - app/models/user.rb
    - app/javascript/application.js
    - config/importmap.rb

key-decisions:
  - "enum :column_name, hash, validate: true (Rails 7+ syntax) chosen — validate: true raises validation error on invalid values rather than ArgumentError, critical for safe form handling"
  - "Composite index [user_id, recorded_at] added now to avoid follow-up migration when Phase 5 timeline queries are built"
  - "ActionText (not an external 'lexxy' gem) used for rich text notes — Rails built-in Trix implementation"
  - "ActionText fixture (action_text_rich_texts.yml) omitted — tests that verify notes build records programmatically where has_rich_text works correctly"
  - "dependent: :destroy on has_many :symptom_logs ensures GDPR data ownership — logs deleted with user"

patterns-established:
  - "Enum pattern: enum :field, { label: integer }, validate: true — established for symptom_type and severity"
  - "Chronological scope: scope :chronological, -> { order(recorded_at: :desc) } — standard ordering for all log queries"
  - "Multi-user fixture pattern: alice (verified_user) and bob (unverified_user) fixtures for isolation tests"

# Metrics
duration: 8min
completed: 2026-03-06
---

# Phase 3 Plan 01: SymptomLog Model Summary

**SymptomLog model with ActionText notes, integer enums (wheezing/coughing/shortness_of_breath/chest_tightness, mild/moderate/severe), composite DB index, and 9 passing model tests — core data structure for all Phase 3 plans**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-03-06T23:54:26Z
- **Completed:** 2026-03-06T00:02:00Z
- **Tasks:** 2 of 2
- **Files modified:** 10

## Accomplishments

- Installed ActionText (Trix editor) with all required migrations applied and wired into importmap + stylesheets
- Created symptom_logs table with integer enum columns (null: false), datetime recorded_at, user_id FK, and composite index on [user_id, recorded_at] for Phase 5 timeline performance
- Created SymptomLog model with full enum definitions (validate: true), presence validations, belongs_to :user, has_rich_text :notes, and chronological scope
- Added has_many :symptom_logs, dependent: :destroy to User model (GDPR data ownership)
- 9 model tests pass; full 48-test suite green with no regressions from ActionText install

## Task Commits

Each task was committed atomically:

1. **Task 1: Install ActionText and create SymptomLog migration and model** - `3009b81` (feat)
2. **Task 2: Add SymptomLog model tests and fixtures** - `d70a105` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `db/migrate/20260306235435_create_symptom_logs.rb` - symptom_logs table with null constraints, user FK, composite index
- `db/migrate/20260306235429_create_active_storage_tables.active_storage.rb` - ActionText dependency (Active Storage)
- `db/migrate/20260306235430_create_action_text_tables.action_text.rb` - action_text_rich_texts table
- `app/models/symptom_log.rb` - SymptomLog model with enums, validations, belongs_to, has_rich_text, chronological scope
- `app/models/user.rb` - Added has_many :symptom_logs, dependent: :destroy
- `app/javascript/application.js` - ActionText/Trix JS wired in via action_text:install
- `config/importmap.rb` - ActionText/Trix importmap entries
- `app/assets/stylesheets/actiontext.css` - Trix editor stylesheet
- `test/models/symptom_log_test.rb` - 9 model tests covering all validations, enums, rich text, and ordering
- `test/fixtures/symptom_logs.yml` - alice_wheezing and bob_coughing for multi-user isolation tests

## Decisions Made

- `enum :field, hash, validate: true` (Rails 7+ syntax) — `validate: true` makes invalid enum values produce validation errors instead of raising ArgumentError, which is critical for safe form handling in subsequent plans
- Composite index `[user_id, recorded_at]` added during this plan rather than waiting for Phase 5 — avoids a follow-up migration and optimises timeline queries from day one
- ActionText (Rails built-in Trix) used for rich text notes; no external gem needed
- ActionText fixtures omitted — tests verify notes by building records programmatically, where `has_rich_text` works correctly without fixture complexity

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- symptom_logs table migrated and ready for controller/form work
- SymptomLog model validated, tested, and available via `Current.user.symptom_logs`
- ActionText configured and functioning — rich text notes ready for Trix editor in views
- Fixtures alice_wheezing and bob_coughing available for controller and system tests in Plans 02-04
- No blockers — Plan 02 (SymptomLogs controller + CRUD) can start immediately

---
*Phase: 03-symptom-recording*
*Completed: 2026-03-06*

## Self-Check: PASSED

- app/models/symptom_log.rb: FOUND
- test/models/symptom_log_test.rb: FOUND
- test/fixtures/symptom_logs.yml: FOUND
- app/assets/stylesheets/actiontext.css: FOUND
- db/migrate/20260306235435_create_symptom_logs.rb: FOUND
- Commit 3009b81: FOUND
- Commit d70a105: FOUND
