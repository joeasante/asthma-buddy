# Project State

## Project Reference

See: .ariadna_planning/PROJECT.md (updated 2026-03-08)

**Core value:** A reliable daily tracking companion that surfaces patterns — so users and their doctors actually understand what's happening with their asthma.
**Current focus:** Milestone 2 — Medication & Compliance (starting Phase 10)

## Current Position

Phase: Starting Milestone 2 — Phase 10 (Medication Data Layer) — NOT STARTED
Plan: Milestone 2 roadmap created 2026-03-08
Status: Milestone 1 complete (all 9 phases done including dashboard, trend charts, UI polish, security hardening). Ready to begin Milestone 2.
Last activity: 2026-03-08 — Completed Milestone 1; UI redesign (solid teal dashboard hero card, severity pill buttons, chart improvements); Chart.js invisible bar bug fixed; defense-in-depth hardening on `update_all`; 195 tests pass.

Progress: [░░░░░░░░░░] 0% (Milestone 2)

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
Stopped at: Milestone 2 planning complete — roadmap created, REQUIREMENTS.md updated
Resume file: None
