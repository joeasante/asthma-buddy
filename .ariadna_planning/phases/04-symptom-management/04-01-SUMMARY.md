---
phase: 04-symptom-management
plan: 01
subsystem: ui
tags: [rails, turbo, turbo-stream, turbo-frame, hotwire, crud, authorization]

# Dependency graph
requires:
  - phase: 03-symptom-recording
    provides: SymptomLogsController (index/create), _symptom_log partial, _form partial, Turbo Stream create flow
provides:
  - edit, update, destroy actions on SymptomLogsController with Current.user ownership scoping
  - Inline edit via Turbo Frame (clicking Edit replaces entry with form in place)
  - Turbo Stream destroy removes entry from DOM without page reload
  - Turbo Stream update replaces entry DOM element with updated content
  - Shared _form partial supporting both create (new record) and edit (persisted record)
  - 9 new controller tests covering edit/update/destroy and cross-user authorization (404)
affects: [04-02, 04-symptom-management, phase-5-timeline]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - ActionView::RecordIdentifier included in controller to access dom_id for Turbo Stream targeting
    - turbo_frame_tag dom_id(record) wraps entry partial — Turbo Stream replace targets the frame by id
    - before_action :set_symptom_log with Current.user.symptom_logs.find enforces per-user 404 on cross-user access
    - edit.html.erb wraps form in matching turbo_frame_tag so Turbo Frame click loads form inline
    - form_with model: without url: uses Rails convention (symptom_logs_path for new, symptom_log_path for persisted)

key-files:
  created:
    - app/views/symptom_logs/edit.html.erb
    - app/views/symptom_logs/update.turbo_stream.erb
  modified:
    - config/routes.rb
    - app/controllers/symptom_logs_controller.rb
    - app/views/symptom_logs/_symptom_log.html.erb
    - app/views/symptom_logs/_form.html.erb
    - test/controllers/symptom_logs_controller_test.rb

key-decisions:
  - "ActionView::RecordIdentifier included in controller (not view helper module) to make dom_id available for Turbo Stream targeting in respond_to blocks"
  - "Flash not streamed on update — layout flash has no DOM id to target; entry replacement sufficient for MVP"
  - "Cancel on edit form uses full page reload (data-turbo: false) to avoid needing a show action — simplest correct MVP approach"
  - "edit.html.erb wraps form in turbo_frame_tag matching entry frame id so inline edit works without data-turbo-frame on the Edit link"

patterns-established:
  - "Turbo Frame inline edit pattern: entry partial in turbo_frame_tag, Edit link navigates into same frame, edit.html.erb wraps response in matching frame"
  - "Ownership enforcement via before_action and Current.user.symptom_logs.find — RecordNotFound auto-returns 404"

# Metrics
duration: 3min
completed: 2026-03-07
---

# Phase 4 Plan 01: Symptom Log Edit and Delete Summary

**Inline edit/delete for symptom log entries via Turbo Frame and Turbo Stream — clicking Edit replaces the entry with a form in-place, Delete removes it from the DOM, all enforced with per-user ownership (404 on cross-user access).**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-07T10:34:17Z
- **Completed:** 2026-03-07T10:36:45Z
- **Tasks:** 2
- **Files modified:** 7 (5 modified, 2 created)

## Accomplishments

- Added edit, update, destroy actions to SymptomLogsController with `Current.user.symptom_logs.find` ownership enforcement
- Implemented Turbo Frame inline editing: clicking Edit replaces entry with form; update.turbo_stream.erb replaces entry with updated content on save
- Destroy responds with `turbo_stream.remove` — entry disappears from DOM without page reload
- Updated `_form.html.erb` to work for both create and edit using `form_with model:` — submit label and Cancel link adapt to context
- Added 9 new controller tests covering edit/update/destroy and cross-user 404 authorization; 64 total tests passing

## Task Commits

Each task was committed atomically:

1. **Task 1: Routes, controller actions (edit/update/destroy), and Turbo Stream templates** - `54cb6ce` (feat)
2. **Task 2: Entry partial with Turbo Frame, Edit and Delete buttons; edit form partial** - `50ee278` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `config/routes.rb` - Expanded symptom_logs resource to include edit, update, destroy
- `app/controllers/symptom_logs_controller.rb` - Added edit/update/destroy actions, before_action set_symptom_log, ActionView::RecordIdentifier include
- `app/views/symptom_logs/edit.html.erb` - New: wraps form in turbo_frame_tag for inline edit response
- `app/views/symptom_logs/update.turbo_stream.erb` - New: replaces entry DOM element with updated _symptom_log partial
- `app/views/symptom_logs/_symptom_log.html.erb` - Wrapped in turbo_frame_tag, added Edit and Delete controls
- `app/views/symptom_logs/_form.html.erb` - Removed hardcoded url:, added persisted?-aware submit label and Cancel link
- `test/controllers/symptom_logs_controller_test.rb` - Added 9 tests for edit/update/destroy and authorization

## Decisions Made

- **ActionView::RecordIdentifier in controller:** `dom_id` is a view helper and not available in controller context by default. Including `ActionView::RecordIdentifier` is the idiomatic Rails approach to access it in `respond_to` blocks for Turbo Stream targeting.
- **Flash not streamed on update:** The layout renders flash inline with no DOM id. Streaming flash would require adding an id to the layout element. For MVP, the entry replacement alone is sufficient — flash appears on next full navigation.
- **Cancel uses full page reload:** Avoids needing a `show` action. The Cancel link targets `symptom_logs_path` with `data: { turbo: false }` — user returns to the list. Simplest correct approach.
- **edit.html.erb wraps form in matching turbo_frame_tag:** When the Edit link is inside a turbo_frame, clicking it navigates within that frame. The edit response must return a matching turbo_frame for the content swap to work correctly.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed dom_id unavailable in controller context**
- **Found during:** Task 1 (controller actions)
- **Issue:** `dom_id` is a view helper (`ActionView::RecordIdentifier`) — calling it in controller `respond_to` blocks raised `NoMethodError: undefined method 'dom_id'`
- **Fix:** Added `include ActionView::RecordIdentifier` to SymptomLogsController
- **Files modified:** `app/controllers/symptom_logs_controller.rb`
- **Verification:** All 16 controller tests pass after fix
- **Committed in:** `54cb6ce` (Task 1 commit)

**2. [Rule 2 - Missing Critical] Added edit.html.erb for Turbo Frame inline edit response**
- **Found during:** Task 1 (planning the edit flow)
- **Issue:** The plan specified edit renders "implicitly" but Turbo Frame inline edit requires an explicit `edit.html.erb` that wraps the form in a matching `turbo_frame_tag` — without it, the frame has no matching frame to swap and the edit form would navigate the full page
- **Fix:** Created `app/views/symptom_logs/edit.html.erb` wrapping the form partial in `turbo_frame_tag dom_id(@symptom_log)`
- **Files modified:** `app/views/symptom_logs/edit.html.erb` (new file)
- **Verification:** Edit link loads form inline in tests and routes pass
- **Committed in:** `54cb6ce` (Task 1 commit)

**3. [Rule 2 - Missing Critical] Added 9 controller tests for new actions**
- **Found during:** Task 1 (after implementing actions)
- **Issue:** Plan specified "run existing tests" but new actions had zero test coverage — edit/update/destroy actions and the cross-user 404 authorization requirement had no tests
- **Fix:** Added 9 new tests covering edit/update/destroy (success + invalid + authorization) for both owner and cross-user scenarios
- **Files modified:** `test/controllers/symptom_logs_controller_test.rb`
- **Verification:** 16 controller tests, 64 total tests pass
- **Committed in:** `54cb6ce` (Task 1 commit)

---

**Total deviations:** 3 auto-fixed (1 Rule 1 bug, 2 Rule 2 missing critical)
**Impact on plan:** All fixes necessary for correctness and completeness. No scope creep.

## Issues Encountered

None beyond the auto-fixed deviations above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Edit and delete fully functional with Turbo Frame/Stream inline UX
- All 64 tests passing
- Ready for Phase 4 Plan 02 (next symptom management plan)

---
*Phase: 04-symptom-management*
*Completed: 2026-03-07*

## Self-Check: PASSED

All artifacts verified:
- config/routes.rb - FOUND
- app/controllers/symptom_logs_controller.rb - FOUND
- app/views/symptom_logs/_symptom_log.html.erb - FOUND
- app/views/symptom_logs/_form.html.erb - FOUND
- app/views/symptom_logs/update.turbo_stream.erb - FOUND
- app/views/symptom_logs/edit.html.erb - FOUND
- Commit 54cb6ce - FOUND
- Commit 50ee278 - FOUND
