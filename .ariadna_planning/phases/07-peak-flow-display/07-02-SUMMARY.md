---
phase: 07-peak-flow-display
plan: "02"
subsystem: peak-flow-management
tags: [turbo-stream, turbo-frame, crud, inline-edit, current-user-scoping, wcag]
dependency_graph:
  requires: ["07-01"]
  provides: ["edit/update/destroy for peak_flow_readings", "inline Turbo Frame edit", "Turbo Stream destroy"]
  affects: ["app/views/peak_flow_readings", "app/controllers/peak_flow_readings_controller.rb", "config/routes.rb"]
tech_stack:
  added: []
  patterns:
    - "ActionView::RecordIdentifier included in controller for dom_id in Turbo Stream responses"
    - "before_action :set_peak_flow_reading scoped to Current.user — cross-user requests raise RecordNotFound (404)"
    - "Turbo Frame inline edit: edit.html.erb wraps _form partial in turbo_frame_tag matching row dom_id"
    - "update.turbo_stream.erb uses turbo_stream.replace with _reading_row partial — zone recalculated via model before_save"
    - "update_error.turbo_stream.erb re-renders edit form inside turbo_frame_tag to keep frame in DOM"
    - "destroy.turbo_stream.erb uses turbo_stream.remove — mirrors symptom_logs pattern"
    - "button_to Delete with turbo_confirm triggers custom confirm dialog from application.html.erb"
key_files:
  created:
    - app/views/peak_flow_readings/edit.html.erb
    - app/views/peak_flow_readings/update.turbo_stream.erb
    - app/views/peak_flow_readings/update_error.turbo_stream.erb
    - app/views/peak_flow_readings/destroy.turbo_stream.erb
  modified:
    - config/routes.rb
    - app/controllers/peak_flow_readings_controller.rb
    - app/views/peak_flow_readings/_reading_row.html.erb
decisions:
  - "edit/update/destroy routes added to peak_flow_readings resource — full CRUD except create (already exists)"
  - "ActionView::RecordIdentifier included in PeakFlowReadingsController matching Phase 4 symptom_logs pattern"
  - "update_error.turbo_stream.erb wraps form in both turbo_stream.replace and turbo_frame_tag — outer replace targets DOM, inner frame keeps subsequent edits functional"
  - "has_personal_best: false passed to _form partial in edit context — suppresses personal best banner for existing users"
metrics:
  duration: "~2 min"
  completed: "2026-03-07"
  tasks_completed: 2
  files_changed: 7
---

# Phase 7 Plan 02: Edit/Update/Destroy for Peak Flow Readings Summary

**One-liner:** Full edit/destroy CRUD for peak flow readings via Current.user-scoped controller actions, inline Turbo Frame edit form, and Turbo Stream replace/remove responses.

## What Was Built

Wired up edit, update, and destroy for peak flow readings, completing CRUD (create was already implemented in Phase 6). The pattern mirrors Phase 4 symptom log management exactly.

### Routes

`config/routes.rb` updated to include `edit`, `update`, and `destroy` alongside the existing `new`, `create`, and `index`:

```ruby
resources :peak_flow_readings, path: "peak-flow-readings", only: %i[ new create index edit update destroy ]
```

### Controller (`app/controllers/peak_flow_readings_controller.rb`)

- `include ActionView::RecordIdentifier` added at class level for `dom_id` access in Turbo Stream responses
- `before_action :set_peak_flow_reading, only: %i[edit update destroy]` — scoped to `Current.user.peak_flow_readings.find(params[:id])`, raising `ActiveRecord::RecordNotFound` (404) for cross-user requests
- `edit` action: empty, relies on `set_peak_flow_reading` before_action
- `update` action: calls `@peak_flow_reading.update`, responds with `turbo_stream` on success or renders `:update_error` with 422 on failure
- `destroy` action: calls `@peak_flow_reading.destroy`, responds with `turbo_stream` or redirect

### Views

| File | Purpose |
|------|---------|
| `edit.html.erb` | Turbo Frame wrapping existing `_form` partial for inline edit |
| `update.turbo_stream.erb` | Replaces reading row with recalculated zone via `turbo_stream.replace` |
| `update_error.turbo_stream.erb` | Replaces frame with edit form showing validation errors on 422 |
| `destroy.turbo_stream.erb` | Removes reading row via `turbo_stream.remove` |
| `_reading_row.html.erb` | Updated with Edit link and Delete button (turbo-confirm dialog) |

## Task Commits

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Routes + controller edit/update/destroy | 8d5a52a | config/routes.rb, app/controllers/peak_flow_readings_controller.rb |
| 2 | Views + reading row Edit/Delete buttons | 6846096 | 4 new view files, _reading_row.html.erb |

## Deviations from Plan

None — plan executed exactly as written.

## Verification Results

- `bin/rails routes | grep peak_flow` — edit, update, destroy routes confirmed
- `bin/rails test test/controllers/peak_flow_readings_controller_test.rb` — 13 runs, 43 assertions, 0 failures, 0 errors, 0 skips

## Self-Check: PASSED

Files confirmed present:
- app/views/peak_flow_readings/edit.html.erb — FOUND
- app/views/peak_flow_readings/update.turbo_stream.erb — FOUND
- app/views/peak_flow_readings/update_error.turbo_stream.erb — FOUND
- app/views/peak_flow_readings/destroy.turbo_stream.erb — FOUND
- app/views/peak_flow_readings/_reading_row.html.erb — FOUND (modified)

Commits confirmed:
- 8d5a52a — feat(07-02): routes + controller edit/update/destroy actions
- 6846096 — feat(07-02): edit/update/destroy views + reading row Edit/Delete buttons
