# Project State

## Project Reference

See: .ariadna_planning/PROJECT.md (updated 2026-03-06)

**Core value:** A reliable daily tracking companion that surfaces patterns — so users and their doctors actually understand what's happening with their asthma.
**Current focus:** Phase 7 — Peak Flow Display

## Current Position

Phase: 7 of 9 (Peak Flow Display) — IN PROGRESS
Plan: 1 of 3 in phase 07 (07-01 complete)
Status: Phase 7 Plan 1 Complete — filterable paginated index with zone badges and nav link
Last activity: 2026-03-07 — Completed 07-01: zone badge CSS (WCAG AA), filter chips, pagination, _reading_row/_filter_bar/_pagination partials, Peak Flow nav link; 13 controller tests, 0 failures

Progress: [███████░░░] 33%

## Performance Metrics

**Velocity:**
- Total plans completed: 18
- Average duration: ~5.1 min
- Total execution time: ~82 min

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-foundation | 4 | ~28 min | ~7 min |
| 02-authentication | 3 | ~21 min | ~7 min |
| 03-symptom-recording | 2 | ~12 min | ~6 min |
| 04-symptom-management | 2 | ~11 min | ~5.5 min |
| 05-symptom-timeline | 3 | ~12 min | ~4 min |
| 06-peak-flow-recording | 5 | ~22 min | ~4.4 min |
| 07-peak-flow-display | 1 | ~2 min | ~2 min |


**Recent Trend:**
- Last 5 plans: 06-02 (5 min), 06-03 (1 min), 06-04 (3 min), 06-05 (5 min), 07-01 (2 min)
- Trend: stable — recent plans averaging ~1-5 min

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
- turbo_frame_tag wraps _timeline_row so Edit/Delete buttons are present and inline edit targets the frame — id=timeline_list on <ol> enables Turbo Stream prepend on create (05-02)
- create.turbo_stream.erb targets timeline_list using timeline_row partial; update.turbo_stream.erb uses timeline_row partial — consistent with Phase 5 view architecture (05-02)
- filter_bar moved INSIDE turbo_frame_tag 'timeline_content' — supersedes 05-01 outside-frame decision; root cause of broken active-chip state was bar never re-rendered on chip click (05-03)
- @severity_counts in create uses full user history (no date filter) — trend bar matches fresh page load behavior (05-03)
- trend_bar wrapped in div#trend_bar for stable turbo_stream.replace target — live update on create now works (05-03)
- Zone calculation uses personal best at reading time (recorded_at <= self.recorded_at), not current personal best — ensures historical accuracy (06-01)
- zone column is nullable; enum uses validate: { allow_nil: true } — nil zone when no personal best exists is a valid state (06-01)
- PersonalBestRecord validation range 100-900 L/min — covers physiologically plausible peak flow values (06-01)
- before_save :assign_zone on PeakFlowReading — zone is always derived, never manually set by callers (06-01)
- form_with model: personal_best_record, url: settings_personal_best_path — model for error binding only, URL explicit for non-resourceful route (06-02)
- recorded_at merged server-side in personal_best_params — form never exposes timestamp, prevents client-side tampering (06-02)
- turbo_stream.prepend "main-content" used for zone-aware flash in create.turbo_stream.erb — main-content is the established skip-link target DOM id, no separate flash container needed (06-03)
- zone_flash_message reads personal_best_at_reading_time after before_save :assign_zone runs — zone and percentage always consistent (06-03)
- System test sign_in_as defined as local helper using form-based login — SessionTestHelper only loads for ActionDispatch::IntegrationTest, not ApplicationSystemTestCase (06-04)
- execute_script to strip HTML5 required attribute before blank-submit system test — prevents browser-native validation blocking server-side validation path (06-04)
- id="flash-messages" div always rendered unconditionally in layout — empty div cheaper than missing Turbo Stream replace target (06-05)
- turbo_stream.replace "flash-messages" supersedes turbo_stream.prepend "main-content" from 06-03 — replace is correct primitive for non-accumulating flash (06-05)
- turbo_frame_tag wrapper supplied in create.turbo_stream.erb not in _form partial — frame lifecycle managed at stream layer, partial renders inner content only (06-05)
- html_safe + raw() for controller-generated HTML in Turbo Stream templates — marked at source in controller, rendered unescaped in template (06-05)
- filter_bar rendered INSIDE turbo_frame_tag readings_content — matches 05-03 precedent; active chip state re-renders correctly on filter click (07-01)
- zone-badge background-fill pill approach (not text-colour only) — visually distinguishable at a glance without reading zone label; WCAG AA contrast on all three zones (07-01)
- edit/delete stubs intentionally omitted from _reading_row — routes do not exist yet; 07-02 adds them when routes are in place to avoid routing errors at render time (07-01)

### Pending Todos

None yet.

### Blockers/Concerns

None yet.

## Session Continuity

Last session: 2026-03-07
Stopped at: Completed 07-01-PLAN.md — filterable paginated peak flow index: zone badge CSS (WCAG AA), filter chips, pagination, _reading_row/_filter_bar/_pagination partials, Peak Flow nav link; 13 controller tests, 0 failures
Resume file: None
