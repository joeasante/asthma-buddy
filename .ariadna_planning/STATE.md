# Project State

## Project Reference

See: .ariadna_planning/PROJECT.md (updated 2026-03-06)

**Core value:** A reliable daily tracking companion that surfaces patterns — so users and their doctors actually understand what's happening with their asthma.
**Current focus:** Phase 3 — Symptom Logging

## Current Position

Phase: 3 of 9 (Symptom Recording) — IN PROGRESS
Plan: 1 of 5 in phase 03 (03-01 complete)
Status: Phase 3 Plan 1 Complete, Plan 2 Next
Last activity: 2026-03-06 — Completed 03-01: SymptomLog model, ActionText install, 9 model tests, all migrations applied

Progress: [█████░░░░░] 19%

## Performance Metrics

**Velocity:**
- Total plans completed: 8
- Average duration: ~7 min
- Total execution time: ~57 min

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-foundation | 4 | ~28 min | ~7 min |
| 02-authentication | 3 | ~21 min | ~7 min |
| 03-symptom-recording | 1 | ~8 min | ~8 min |

**Recent Trend:**
- Last 5 plans: 02-01 (3 min), 02-02 (3 min), 02-03 (15 min), 03-01 (8 min)
- Trend: steady execution, model-only plan fastest so far

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- Multi-user isolation from day 1 (architectural constraint — enforced at controller/query level throughout all phases)
- SQLite in WAL mode — database.yml `properties: { journal_mode: wal }` + configure_connection initializer (01-01)
- Rails 8 auth generator, no Devise (implemented in Phase 2)
- Lexxy for notes rich text (used in Phase 3)
- Initializer as belt-and-suspenders WAL guarantee via SQLite3Adapter#configure_connection prepend (01-01)
- lang="en" on <html> for WCAG 2.2 AA compliance added at layout creation (01-02)
- ARIA landmark roles (banner, navigation, main, contentinfo) established in base layout (01-02)
- Flash messages use role=status (notice) and role=alert (alert) for screen reader semantics (01-02)
- id="main-content" on <main> for skip-link target — Phase 9 adds skip link (01-02)
- application_system_test_case.rb lives in test/ (not test/system/) — Rails load path convention (01-03)
- System tests use headless Chrome at 1400×1400 screen size (01-03)
- actions/checkout@v4 — v6 does not exist, CI would have failed on push (01-04)
- Staging deploy deferred — config/deploy.yml retains placeholders until VPS provisioned (01-04)
- Rails 8 auth generator uses email_address column (not email) — kept convention rather than renaming (02-01)
- email_verified_at column added to users now but not enforced until 02-02 (deferred gate) (02-01)
- HomeController gets allow_unauthenticated_access to keep home page public until 02-03 sets up route guards (02-01)
- PasswordsControllerTest assert_notice uses p selector to match application layout flash tags (02-01)
- Custom GET route /email_verification/:token used — singular resource show has no ID segment so param: :token has no path effect (02-02)
- generates_token_for :email_verification chosen over DB token column — stateless signed tokens, no migration needed (02-02)
- deliver_later used for non-blocking signup flow via Solid Queue (02-02)
- 2-week cookie expiry chosen over permanent (20-year) for security (02-03)
- generates_token_for :password_reset with 1-hour expiry overrides has_secure_password 15-min default (02-03)
- System tests use ActiveJob inline adapter to make deliver_later synchronous in Puma server thread (02-03)
- click_button used over click_on in system tests to avoid ambiguous matches between nav links and form submits (02-03)
- enum :field, hash, validate: true (Rails 7+ syntax) — validate: true raises validation error on invalid values rather than ArgumentError, critical for safe form handling (03-01)
- Composite index [user_id, recorded_at] added in 03-01 to avoid follow-up migration when Phase 5 timeline queries are built (03-01)
- ActionText (not an external gem) used for rich text notes — Rails built-in Trix implementation (03-01)
- dependent: :destroy on has_many :symptom_logs ensures GDPR data ownership — logs deleted with user (03-01)

### Pending Todos

None yet.

### Blockers/Concerns

None yet.

## Session Continuity

Last session: 2026-03-06
Stopped at: Completed 03-01-PLAN.md — SymptomLog model, ActionText, 9 model tests, 48 total tests passing
Resume file: None
