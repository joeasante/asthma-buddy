# Phase 11 Context: Medication Management UI

**Gathered:** 2026-03-08 (inline, pre-planning)

---

## Decisions (LOCKED — honor exactly)

### Routes: `/settings/medications`
Medications are nested under Settings — consistent with account management coming in Phase 16.
- Index: `GET /settings/medications`
- New/create: `GET/POST /settings/medications/new`
- Edit/update: `GET/PATCH /settings/medications/:id/edit`
- Destroy: `DELETE /settings/medications/:id`
- Use `namespace :settings` or `scope '/settings'` in routes.

### Edit Flow: Turbo Frame inline editing
Edit form replaces the medication card in-place via Turbo Frame — no page navigation.
- Each medication card wrapped in `turbo_frame_tag dom_id(medication)`
- Edit link targets the same frame; edit form renders inside the frame
- Update responds with `turbo_stream.replace` or Turbo Frame redirect (422 for validation errors, 303 for success)

### Settings Navigation: Simple sub-sections
Single Settings page (`/settings`) with Medications as a section.
- Phase 16 will add Account Deletion to the same settings page
- No sidebar/tab nav required — keep it simple

---

## Claude's Discretion (implementation choices)

- Exact routing approach (`namespace :settings` vs `scope '/settings'`) — planner's call
- Whether to use a SettingsController for the index page or redirect straight to `/settings/medications`
- CSS layout for the medication cards (list vs grid)
- Empty state copy and CTA button text
- Form field order and grouping (planner decides based on existing form patterns)

---

## Deferred Ideas (OUT OF SCOPE — do NOT include)

- Medication detail/show page (not needed — list + inline edit covers the UX)
- Medication search or filter
- Import/export medications
- Medication reminders or notifications (Phase 17 scope)
- Settings sidebar navigation
