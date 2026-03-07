# Project State

## Project Reference

See: .ariadna_planning/PROJECT.md (updated 2026-03-06)

**Core value:** A reliable daily tracking companion that surfaces patterns — so users and their doctors actually understand what's happening with their asthma.
**Current focus:** Phase 5 — Symptom Timeline

## Current Position

Phase: 5 of 9 (Symptom Timeline) — IN PROGRESS
Plan: 1 of N in phase 05 (05-01 complete)
Status: Phase 5 Plan 1 Complete
Last activity: 2026-03-07 — Completed 05-01: Filtered, paginated symptom timeline with Turbo Frame partial refresh, severity trend bar, CSS custom property color palette; 88 total tests passing

Progress: [██████░░░░] 27%

## Performance Metrics

**Velocity:**
- Total plans completed: 12
- Average duration: ~6 min
- Total execution time: ~67 min

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-foundation | 4 | ~28 min | ~7 min |
| 02-authentication | 3 | ~21 min | ~7 min |
| 03-symptom-recording | 2 | ~12 min | ~6 min |
| 04-symptom-management | 2 | ~11 min | ~5.5 min |
| 05-symptom-timeline | 1 | ~3 min | ~3 min |


**Recent Trend:**
- Last 5 plans: 03-02 (4 min), 04-01 (3 min), 04-02 (8 min), 05-01 (3 min)
- Trend: stable — recent UI plans averaging ~3-5 min

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
- sign_in_as helper used in controller tests instead of POST session_url — consistent with existing test suite and correct fixture password (03-02)
- turbo_frame_tag wraps form and list for targeted Turbo Stream replace/prepend by DOM id (03-02)
- HTTP 422 on validation failure required for Turbo Drive to process error stream instead of treating as redirect (03-02)
- ActionView::RecordIdentifier included in controller to access dom_id for Turbo Stream targeting in respond_to blocks (04-01)
- Flash not streamed on update — layout flash has no DOM id to target; entry replacement sufficient for MVP (04-01)
- Cancel on edit form uses full page reload (data-turbo: false) to avoid needing a show action — simplest correct MVP approach (04-01)
- edit.html.erb wraps form in turbo_frame_tag matching entry frame id so inline edit works without data-turbo-frame on the Edit link (04-01)
- button_to renders as <form> — use specific input name selectors not bare "form" to assert edit form absence in system tests (04-02)
- Cross-user 404 in system test: assert edit form inputs absent rather than assert URL change — Rails error page stays at same URL (04-02)
- Manual pagination (no kaminari/pagy) via SymptomLog.paginate class method returning [records, total_pages, page] tuple — avoids gem dependency for simple 25-per-page use case (05-01)
- Filter bar sits OUTSIDE turbo_frame_tag 'timeline_content' — chip links and date form target the frame without being nested inside it (05-01)
- dom_id on _timeline_row article preserves Turbo Stream destroy targeting and existing controller test assertions (05-01)
- CSS custom properties (--severity-mild/moderate/severe) in symptom_timeline.css establish severity/zone color palette reused by Phase 6+ peak flow (05-01)

### Pending Todos

None yet.

### Blockers/Concerns

None yet.

## Session Continuity

Last session: 2026-03-07
Stopped at: Completed 05-01-PLAN.md — Filtered paginated symptom timeline with Turbo Frame refresh, severity trend bar, CSS color palette; 88 total tests passing
Resume file: None
