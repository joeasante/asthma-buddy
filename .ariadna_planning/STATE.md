# Project State

## Project Reference

See: .ariadna_planning/PROJECT.md (updated 2026-03-08)

**Core value:** A reliable daily tracking companion that surfaces patterns — so users and their doctors actually understand what's happening with their asthma.
**Current focus:** Milestone 2 — Medication & Compliance (starting Phase 10)

## Current Position

Phase: Phase 10 (Medication Data Layer) — IN PROGRESS
Plan: 10-03 complete — Medication domain methods and refilled_at column
Status: 10-03 done (remaining_doses, days_of_supply_remaining, refilled_at, 12 new tests passing, 241 total). Ready for 10-04.
Last activity: 2026-03-08 — Phase 10 Plan 03: remaining_doses/days_of_supply_remaining instance methods, refilled_at datetime column, 12 model tests (241 tests total).

Progress: [███░░░░░░░] 30% (Milestone 2 — 3/~10 plans complete)

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
Stopped at: Phase 10 Plan 03 complete — remaining_doses/days_of_supply_remaining, refilled_at, 12 new tests (241 total)
Resume file: None
