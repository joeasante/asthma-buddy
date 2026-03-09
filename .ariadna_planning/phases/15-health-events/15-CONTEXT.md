---
phase: 15
gathered: 2026-03-09
method: inline
---

# Phase 15 Context: Health Events

## Decisions (Locked)

**What's already built — do NOT re-implement:**
- `HealthEvent` model with `event_type` enum (hospital_visit, gp_appointment, illness, medication_change, other), `recorded_at` datetime, `ended_at` nullable datetime, ActionText `notes`, `point_in_time?` helper, `ongoing?` helper, `ended_at_after_recorded_at` validation, `POINT_IN_TIME_TYPES` constant, `recent_first` scope
- `HealthEventsController` with index, new, create, edit, update, destroy — all fully wired, user-scoped via `Current.user`
- Full view set: `index.html.erb`, `new.html.erb`, `edit.html.erb`, `_form.html.erb`, `_event_row.html.erb`, `destroy.turbo_stream.erb`
- `end_date_controller.js` Stimulus controller handling point-in-time vs duration event type toggle and still-ongoing checkbox
- CSS in `health_events.css`
- Route: `resources :health_events, path: "medical-history"`
- Feature renamed "Medical History" throughout (nav, headings, breadcrumbs, notices)

**Column naming differs from original roadmap spec:**
- Roadmap said `started_on` / `ended_on` (date columns)
- Built version uses `recorded_at` (datetime, matches all other models) and `ended_at` (nullable datetime)
- Plans MUST use `recorded_at` and `ended_at` — do NOT reference `started_on` or `ended_on`

**Scope of Phase 15 plans:**
Plans cover only what is NOT yet done:
1. **Test coverage** for everything built: model tests, controller tests, system tests
2. **Chart marker integration** — health events as vertical overlays on the peak flow chart

**Chart markers approach: canvas overlay (no new plugin)**
- Draw vertical markers directly on the Chart.js canvas inside the existing `chart_controller.js` Stimulus controller
- No new importmap pins, no new gems
- Pass health event data as JSON from `DashboardController` alongside existing `@chart_data`
- Each marker: vertical line at the event's date, colour-coded by event type, with a small label or tooltip on hover/tap
- Only events whose `recorded_at` date falls within the chart's 7-day window should be rendered

## Claude's Discretion

- Test fixture content and exact assertion style
- How hover/tap tooltip is implemented on the canvas (title callback or custom tooltip plugin already loaded with Chart.js)
- Whether chart markers are also shown on the peak flow readings index page chart (if one exists) — planner decides based on what's in the codebase

## Deferred Ideas

- Showing health events as annotations on the symptom timeline
- Any new event types beyond what's already in the enum
- A dedicated "show" page for individual health events
