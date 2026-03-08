# Project State

## Project Reference

See: .ariadna_planning/PROJECT.md (updated 2026-03-08)

**Core value:** A reliable daily tracking companion that surfaces patterns — so users and their doctors actually understand what's happening with their asthma.
**Current focus:** Milestone 2 — Medication & Compliance (starting Phase 10)

## Current Position

Phase: Phase 12 (Dose Logging) — IN PROGRESS
Plan: 12-02 complete — Dose log views: inline form, history section, Turbo Stream responses
Status: Plan 02 done. 256 tests passing (no regressions). All Turbo Stream view files in place.
Last activity: 2026-03-08 — Phase 12 Plan 02: medication card updated with dose log form + history, Turbo Stream responses, N+1 fix.

Progress: [███████░░░] 70% (Milestone 2 — 7/~10 plans complete)

## Milestone 1 Summary (v1.0 — Complete)

All 9 phases delivered:
- Phase 1: Foundation (Rails, SQLite WAL, CI, Kamal)
- Phase 2: Authentication (signup, email verification, login, password reset)
- Phase 3: Symptom Recording (types, severity, notes, ActionText/Lexxy)
- Phase 4: Symptom Management (edit, delete, Turbo Streams)
- Phase 5: Symptom Timeline (filter bar, severity trends, pagination)
- Phase 6: Peak Flow Recording (readings, personal best, zone calculation)
- Phase 7: Peak Flow Display (zone colour coding, edit/delete)
- Phase 8: Peak Flow Trends (Chart.js via Stimulus, day labels, y-axis fix)
- Phase 9: Dashboard + Accessibility + Polish (solid teal hero card, symptom pills, chart above filter)

## Performance Metrics

**Milestone 1 Velocity:**
- Total plans completed: ~25+
- Tests at close: 195 passing

**Milestone 2 Velocity:**
- Phase 10 Plan 01 completed: 2026-03-08 (~6 min, 2 tasks, 5 files, 19 new tests)
- Tests at Phase 10-01 close: 214 passing
- Phase 10 Plan 02 completed: 2026-03-08 (~2 min, 2 tasks, 6 files, 15 new tests)
- Tests at Phase 10-02 close: 229 passing
- Phase 10 Plan 03 completed: 2026-03-08 (~5 min, 2 tasks, 3 files, 12 new tests)
- Tests at Phase 10-03 close: 241 passing
- Phase 11 Plan 01 completed: 2026-03-08 (~1 min, 2 tasks, 2 files, 0 new tests)
- Tests at Phase 11-01 close: 241 passing (no regressions)
- Phase 11 Plan 02 completed: 2026-03-08 (~2 min, 2 tasks, 8 files, 0 new tests)
- Tests at Phase 11-02 close: 241 passing (no regressions)
- Phase 11 Plan 03 completed: 2026-03-08 (~8 min, 2 tasks, 2 files, 15 new tests)
- Tests at Phase 11-03 close: 256 passing (no regressions)
- Phase 12 Plan 01 completed: 2026-03-08 (~2 min, 2 tasks, 2 files, 0 new tests)
- Tests at Phase 12-01 close: 256 passing (no regressions)
- Phase 12 Plan 02 completed: 2026-03-08 (~1 min, 2 tasks, 7 files, 0 new tests)
- Tests at Phase 12-02 close: 256 passing (no regressions)

## Accumulated Context

### Decisions (carried forward to Milestone 2)

All Milestone 1 decisions from previous STATE.md apply. Key carry-forwards:

- **Stack constraint**: Rails 8 Omakase — ERB, Turbo, Stimulus, Vanilla CSS, no frontend frameworks
- **Multi-user isolation**: All queries scoped via `Current.user` — enforced at controller and model layer
- **Lexxy rich text**: `gem "lexxy"` replaces Trix; used for user notes; do NOT reference ActionText/Trix
- **enum syntax**: `enum :field, hash, validate: true` (Rails 7+ syntax) — validate: true raises validation error
- **Chart.js**: Loaded via importmap; Stimulus controller `chart_controller.js`; `toDayLabel()` for day labels; `yMin` buffer formula for bar charts
- **Turbo Streams**: filter_bar INSIDE turbo_frame_tag (05-03 precedent)
- **Flash**: `id="flash-messages"` div always rendered; use `turbo_stream.replace "flash-messages"` for non-accumulating flash
- **Pagination**: Manual `.paginate` class method returning `[records, total_pages, page]` — no kaminari/pagy
- **Defense-in-depth**: `update_all` always includes `user_id: user.id` guard even when IDs are pre-filtered by user scope
- **CSS**: Propshaft pipeline; CSS custom properties on `:root` in `application.css`; zone colours in `--severity-*` and `ZONE_COLORS` JS constant

### Phase 12 Plan 02 Decisions (2026-03-08)

- **DoseLog.new(medication:) not medication.dose_logs.new in views**: Avoids pushing unsaved record into eager-loaded in-memory association array (MEMORY.md safety rule)
- **Ruby-side sort for index view dose history**: sort_by(&:recorded_at).reverse.first(5) uses eager-loaded association — zero additional DB queries
- **Turbo Stream responses re-query fresh**: @medication.dose_logs.chronological.limit(5) after save/destroy guarantees correct SQL order
- **flash.now[:notice] before respond_to**: Required so flash partial rendered via turbo_stream.replace receives the notice value

### Phase 12 Plan 01 Decisions (2026-03-08)

- **Nested resource isolation pattern**: set_dose_log uses @medication.dose_logs.find — transitively scoped to Current.user via set_medication; no separate user check on dose log needed
- **Build via @medication.dose_logs.new**: Not Current.user.dose_logs.new(medication:) — avoids pushing unsaved record into user association in-memory array (MEMORY.md safety rule)
- **Strong params for dose logs**: Only :puffs and :recorded_at permitted — :user_id and :medication_id sourced from Current.user and URL params, never from form

### Phase 11 Plan 03 Decisions (2026-03-08)

- **System test sign_in_as asserts dashboard_url**: HomeController redirects authenticated users to /dashboard; assert_current_path root_url always fails after sign-in
- **Custom confirm dialog in system tests**: confirm_controller.js (Stimulus) replaces native window.confirm with a <dialog> modal; Capybara's accept_confirm only works with native dialogs; tests click dialog.confirm-dialog button[data-action='confirm#accept'] directly
- **Optional fields system tests assert via DOM**: Medication.find_by in test thread returns nil due to SQLite WAL + transactional tests cross-thread visibility; assert by navigating to index and checking card text instead

### Phase 11 Plan 02 Decisions (2026-03-08)

- **Cancel link uses turbo_frame data attribute**: `data: { turbo_frame: dom_id(medication) }` pointing to `settings_medications_path` — Turbo loads the matching frame from index response, restoring the card without full reload or separate show action
- **Form reset uses Current.user.medications.new**: Consistent with symptom_logs pattern; avoids pushing unsaved record into user association in-memory array (MEMORY.md safety rule)
- **rubocop does not lint ERB files**: This project's rubocop config does not target .html.erb; parse errors appear on all ERB files when explicitly passed; 241 tests are the verification mechanism

### Phase 11 Plan 01 Decisions (2026-03-08)

- **Settings scope pattern**: `scope '/settings', module: :settings, as: :settings` (not `namespace`) allows coexistence with bare `get "settings"` route without path prefix conflicts
- **Authorization by association scope**: `Current.user.medications.find` — RecordNotFound auto-returns 404; `Medication.find` is never used in settings controllers
- **No show action**: No medication detail page per CONTEXT.md deferred decisions; index + edit inline are sufficient

### Phase 10 Plan 03 Decisions (2026-03-08)

- **doses_per_day zero guard uses blank? || == 0**: Ruby's `blank?` returns false for integer 0 — explicit zero check required to prevent Infinity from division; `0.blank?` is false in Ruby
- **remaining_doses uses dose_logs.sum(:puffs)**: Single SQL SUM aggregate, not Ruby-side sum — zero on empty result, no N+1
- **remaining_doses.to_f before division**: Float coercion ensures float division rather than integer truncation before rounding

### Phase 10 Plan 02 Decisions (2026-03-08)

- **puffs validated as integer > 0**: Zero or negative puffs would corrupt remaining-dose calculations in Plan 10-03
- **Compound index [:medication_id, :recorded_at]**: Added at table creation to support the sum query pattern in Plan 10-03
- **dependent: :destroy on both User and Medication**: Dose logs are meaningless without either parent — cleaned up on either cascade path
- **Cascade test uses DoseLog.exists?**: assert_difference fails when fixtures already hold records for the same medication — scoping to the specific created record is correct

### Phase 10 Plan 01 Decisions (2026-03-08)

- **enum :medication_type stored as integer with validate: true**: Unknown values produce validation errors not ArgumentError — safer for form submissions
- **starting_dose_count allows zero**: An empty inhaler at start is valid; uses greater_than_or_equal_to: 0
- **Optional numeric columns use allow_nil: true**: sick_day_dose_puffs and doses_per_day validated only when present
- **Fixture enum values are raw integers**: Rails fixtures bypass enum accessors; write 0/1/2/3 directly
- **Chronological scope test must scope comparison**: Compare @user.medications.order(...) not Medication.order(...)

### Milestone 2 Key Decisions

- **Medication types**: reliever (SABA), preventer (ICS), combination (ICS+LABA), other — Rails enum
- **Dose tracking**: Starting count − logged doses = remaining; no complex inventory system
- **Low stock threshold**: 14 days of supply remaining triggers warning
- **Adherence indicator**: Dashboard shows ✓/✗ for preventer today — no push notifications
- **Health events**: illness, appointment, prescription_course — shown as markers on peak flow chart
- **Account deletion**: Full cascade via `dependent: :destroy` on all user associations; confirmation step required
- **Onboarding**: Prompted after signup if personal best is not set and no medications added
- **Legal pages**: Static ERB pages; session cookie is essential (no consent banner needed); ToS + Privacy Policy required for public launch

### Pending Todos

None.

### Blockers/Concerns

None.

## Session Continuity

Last session: 2026-03-08
Stopped at: Phase 12 Plan 02 complete — Dose log views: inline form, history section, Turbo Stream responses, N+1 fix, 256 tests passing
Resume file: None
