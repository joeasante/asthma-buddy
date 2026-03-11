# Phase 18 Context: Temporary Medication Courses

## Decisions (LOCKED — honor exactly, do not revisit)

### 1. Auto-archive mechanism
**Decision:** Scope-based — active/archived scopes compute dynamically from `ends_on` date.

- `active_courses` scope: `where(course: true).where("ends_on >= ?", Date.today)`
- `archived_courses` scope: `where(course: true).where("ends_on < ?", Date.today)`
- **No background job. No `archived` boolean column.** Add a DB index on `ends_on`.
- Archival is instant: a course whose end date was yesterday is archived the moment today begins.

### 2. Dose logging on archived courses
**Decision:** Disable dose log buttons on archived courses.

- Active course (ends_on >= today): full dose log button, identical to regular medications.
- Archived course (ends_on < today): no log button. Section is read-only history only.
- No grace window in Phase 18 — keep adherence data clean. Grace window is a future polish task.

### 3. "Past courses" collapsible section
**Decision:** Collapsed by default, with a count badge.

- Label format: `▶ Past courses (N)` where N is the count of archived courses.
- Collapsed on page load. User expands to see history.
- Use Stimulus `disclosure` controller (or equivalent toggle) for expand/collapse.
- Empty state when N = 0: section is hidden entirely (no empty collapsed section).

## Claude's Discretion

- Form field ordering and layout within the course date fields (shown/hidden by checkbox)
- Specific Stimulus controller name(s) for the checkbox→date field toggle
- CSS class naming for the collapsible section
- Whether the count badge updates via Turbo Stream after a course is archived in-session

## Deferred Ideas (Out of scope — do NOT include)

- 24-hour grace window for dose logging on recently archived courses
- `archived_at` timestamp column
- Notifications or reminders when a course is about to end
- Editing an archived course's end date
