---
phase: 18-temporary-medication-courses
plan: 02
subsystem: frontend
tags: [stimulus, turbo, erb, css, forms, views]

# Dependency graph
requires:
  - phase: 18-01
    provides: course/starts_on/ends_on columns, active_courses/archived_courses/non_courses scopes, course_active? predicate

provides:
  - course_toggle_controller.js — Stimulus controller showing/hiding course date fields and doses_per_day on checkbox toggle
  - Updated _form.html.erb with course checkbox and conditional course date fieldset
  - Updated index.html.erb split into @active_medications (regular + active courses) and @archived_courses
  - _course_medication.html.erb — active course card partial (badge, end date, log dose button)
  - _past_courses.html.erb — collapsible past courses section with count badge, archived rows (no log button)
  - Updated MedicationsController: index splits active/archived, medication_params permits :course, :starts_on, :ends_on
  - Updated create.turbo_stream.erb: chooses correct partial for course vs regular medications
  - medications.css with course badge, past-courses disclosure, and field-group--course styles

affects:
  - 18-03 (any additional test or polish plan for courses)
  - Settings medications UI

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Stimulus controller auto-registered via eagerLoadControllersFrom — no manual index.js entry needed"
    - "connect() calls toggle() to restore correct UI state when form re-renders with validation errors"
    - "details/summary for native collapsible past courses — no Stimulus controller needed"
    - "index splits active vs archived in Ruby after one SQL query — no N+1 queries"
    - "turbo_frame_tag wraps both course and archived partials — destroy.turbo_stream.erb works for all"

key-files:
  created:
    - app/javascript/controllers/course_toggle_controller.js
    - app/views/settings/medications/_course_medication.html.erb
    - app/views/settings/medications/_past_courses.html.erb
    - app/assets/stylesheets/medications.css
  modified:
    - app/views/settings/medications/_form.html.erb
    - app/views/settings/medications/index.html.erb
    - app/views/settings/medications/create.turbo_stream.erb
    - app/controllers/settings/medications_controller.rb
    - app/views/layouts/application.html.erb

key-decisions:
  - "eagerLoadControllersFrom auto-registers course_toggle_controller — no manual import in index.js needed"
  - "checkbox target placed directly on the check_box input via data-course-toggle-target — consistent with Stimulus target pattern"
  - "index splits in Ruby (reject/select) after a single .includes(:dose_logs) query — keeps SQL efficient"
  - "details/summary for past courses disclosure — browser-native, zero JS, accessible"
  - "medications.css added to layout inside authenticated? block — same pattern as all other feature CSS"
  - "create.turbo_stream.erb updated to choose course_medication vs medication partial"
  - "destroy.turbo_stream.erb unchanged — turbo_frame_tag dom_id wrapper works for all medication types"

patterns-established:
  - "Course toggle pattern: Stimulus checkbox targets + courseFields/dosesPerDayField targets, connect() restores state on re-render"
  - "Two-section index pattern: active list + optional collapsible past list"

requirements_covered:
  - id: "COURSE-UI-01"
    description: "Medication form has course checkbox that shows/hides date fields via Stimulus"
    evidence: "app/javascript/controllers/course_toggle_controller.js + _form.html.erb data-controller='course-toggle'"
  - id: "COURSE-UI-02"
    description: "Active courses appear in main list with Course badge and end date; have Log dose button"
    evidence: "app/views/settings/medications/_course_medication.html.erb"
  - id: "COURSE-UI-03"
    description: "Past courses section hidden when empty; collapsed by default with count badge when N>=1"
    evidence: "app/views/settings/medications/_past_courses.html.erb + index.html.erb guard"
  - id: "COURSE-UI-04"
    description: "Archived course rows are read-only with no Log dose button"
    evidence: "_past_courses.html.erb — no med-log-details block"
  - id: "COURSE-UI-05"
    description: "medication_params permits :course, :starts_on, :ends_on"
    evidence: "app/controllers/settings/medications_controller.rb medication_params"

# Metrics
duration: ~8min
completed: 2026-03-10
---

# Phase 18 Plan 02: Temporary Medication Courses — UI Layer Summary

**Full UI layer for temporary medication courses: Stimulus-controlled course checkbox on the medication form, updated medications index split into active and past-courses sections, active course card partial, collapsible past courses partial, and CSS for all new components.**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-03-10T19:18:47Z
- **Completed:** 2026-03-10T19:26:00Z
- **Tasks:** 2
- **Files created:** 4
- **Files modified:** 5

## Accomplishments

### Task 1: Stimulus course-toggle controller and updated medication form

- Created `app/javascript/controllers/course_toggle_controller.js` with `checkbox`, `courseFields`, and `dosesPerDayField` targets
- `toggle()` shows/hides course date fields and doses_per_day; disables hidden inputs to exclude them from form submission
- `connect()` calls `toggle()` on mount — correctly restores UI state when the form re-renders with validation errors on a course medication
- Updated `_form.html.erb` to add `data-controller="course-toggle"` to form_with, added course checkbox with `data-course-toggle-target="checkbox"`, wrapped doses_per_day in `dosesPerDayField` target, added hidden `courseFields` section with starts_on/ends_on date inputs
- Auto-registered by `eagerLoadControllersFrom` — no manual entry in index.js needed

### Task 2: Index view split, course partials, controller params, CSS

- `MedicationsController#index` now loads all medications in one query then splits in Ruby: `@active_medications` (non-courses + active courses) and `@archived_courses` (ended courses)
- `medication_params` permits `:course, :starts_on, :ends_on`
- `index.html.erb` renders active medications section and optional past courses section (guarded by `@archived_courses.any?`)
- Active courses use the `_course_medication.html.erb` partial — shows Course badge, medication type badge, end date, remaining doses, and full Log dose panel
- Archived courses use `_past_courses.html.erb` — native `<details>`/`<summary>` collapse, count badge, archived rows with overflow menu (remove only, no log dose)
- `create.turbo_stream.erb` updated to choose `course_medication` vs `medication` partial based on `@medication.course?`
- `destroy.turbo_stream.erb` unchanged — `turbo_frame_tag dom_id(medication)` wrapper works for all medication types
- `medications.css` created with course badge styles, past-courses disclosure animation, archived row opacity, and course fieldset left-border
- `medications.css` added to application layout inside `authenticated?` block

## Requirements Covered

| REQ-ID | Requirement | Evidence |
|--------|-------------|----------|
| COURSE-UI-01 | Form course checkbox shows/hides date fields via Stimulus | `course_toggle_controller.js`, `_form.html.erb` |
| COURSE-UI-02 | Active courses in main list with badge, end date, log button | `_course_medication.html.erb` |
| COURSE-UI-03 | Past courses section hidden when empty; collapsed with count badge | `_past_courses.html.erb`, `index.html.erb` guard |
| COURSE-UI-04 | Archived rows read-only (no Log dose button) | `_past_courses.html.erb` |
| COURSE-UI-05 | medication_params permits :course, :starts_on, :ends_on | `medications_controller.rb` |

## Task Commits

1. **Task 1: Stimulus course-toggle controller and updated medication form** — `d7d070a`
2. **Task 2: Index split, course partials, controller params, CSS** — `de40931`

## Files Created/Modified

- `app/javascript/controllers/course_toggle_controller.js` — CREATED: Stimulus checkbox toggle controller
- `app/views/settings/medications/_form.html.erb` — MODIFIED: course-toggle controller, checkbox, courseFields section
- `app/views/settings/medications/_course_medication.html.erb` — CREATED: active course card partial
- `app/views/settings/medications/_past_courses.html.erb` — CREATED: collapsible past courses partial
- `app/views/settings/medications/index.html.erb` — MODIFIED: two-section split with @active_medications and optional @archived_courses
- `app/views/settings/medications/create.turbo_stream.erb` — MODIFIED: course vs regular partial selection
- `app/controllers/settings/medications_controller.rb` — MODIFIED: index split, medication_params with course fields
- `app/assets/stylesheets/medications.css` — CREATED: course badge, past-courses, field-group--course styles
- `app/views/layouts/application.html.erb` — MODIFIED: added medications CSS to authenticated block

## Decisions Made

- **eagerLoadControllersFrom auto-registers controllers:** No manual `import` + `register` in `index.js` — the file name `course_toggle_controller.js` is sufficient for auto-registration
- **Checkbox target on the input element:** `data-course-toggle-target="checkbox"` placed directly on the `check_box` input via the data hash — not on a wrapper div — consistent with Stimulus target conventions
- **Ruby-side index split:** `@active_medications` and `@archived_courses` computed with `reject`/`select` in Ruby after a single `.includes(:dose_logs)` SQL query — keeps N+1 off the table
- **Native details/summary for past courses disclosure:** Browser-native collapse with no Stimulus controller required; CSS `::before` pseudo-element provides the chevron indicator with CSS transition
- **destroy.turbo_stream.erb unchanged:** Both regular and course partials wrap in `turbo_frame_tag dom_id(medication)` so the existing `turbo_stream.remove` correctly removes any medication type
- **medications.css uses CSS custom properties exclusively:** All spacing tokens (`--space-*`), colours (`--brand`, `--brand-light`, `--text-3`, `--surface-2`, `--text-2`), no raw hex values

## Deviations from Plan

- **`data-course-toggle-target="checkbox"` placed on the input, not a wrapper div:** The plan showed the checkbox target on a `<div class="field field--checkbox">` wrapper. Since Stimulus targets can be on any element and the toggle logic reads `this.checkboxTarget.checked`, placing the target directly on the checkbox input (via Rails `check_box` data hash) is cleaner and more conventional. The wrapper div still has the `field field--checkbox` classes for styling.

## Issues Encountered

None.

## User Setup Required

None.

## Next Phase Readiness

- All UI for temporary medication courses is complete
- Course medications are distinguishable from regular medications in the list
- Active courses have full log-dose functionality; archived courses are read-only
- Course checkbox form toggle works via Stimulus; form re-renders correctly after validation errors
- 19 medications controller tests passing, no regressions

## Self-Check: PASSED

All files verified:
- `app/javascript/controllers/course_toggle_controller.js` — FOUND
- `app/views/settings/medications/_form.html.erb` — FOUND (data-controller="course-toggle" present)
- `app/views/settings/medications/_course_medication.html.erb` — FOUND
- `app/views/settings/medications/_past_courses.html.erb` — FOUND
- `app/views/settings/medications/index.html.erb` — FOUND (@active_medications present)
- `app/views/settings/medications/create.turbo_stream.erb` — FOUND (course? branch present)
- `app/controllers/settings/medications_controller.rb` — FOUND (:course, :starts_on, :ends_on permitted)
- `app/assets/stylesheets/medications.css` — FOUND
- `app/views/layouts/application.html.erb` — FOUND (medications stylesheet tag present)
- Commit `d7d070a` — FOUND
- Commit `de40931` — FOUND
- Tests: 19 runs, 47 assertions, 0 failures — PASSED

---
*Phase: 18-temporary-medication-courses*
*Completed: 2026-03-10*
