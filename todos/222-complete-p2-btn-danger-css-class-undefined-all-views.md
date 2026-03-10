---
status: pending
priority: p2
issue_id: "222"
tags: [frontend, css, code-review, ui]
dependencies: []
---

# `btn-danger` CSS Class Undefined — Delete Buttons Across 4 Views Render Unstyled

## Problem Statement

`class: "btn-danger"` is used on delete/destroy submit buttons in 4 views, but no `.btn-danger` rule exists in any stylesheet. The correct existing class is `.btn-delete` (defined in `application.css` at line 771). This means delete buttons across the app currently render with browser-default button styling — no red colour, no danger visual cue. Users cannot visually distinguish destructive actions from regular actions.

## Findings

**Flagged by:** pattern-recognition-specialist

**Occurrences of `btn-danger` (undefined class):**
- `app/views/settings/show.html.erb` line 61 — account deletion button (Phase 16, new)
- `app/views/health_events/show.html.erb` line 18 — pre-existing
- `app/views/symptom_logs/show.html.erb` line 18 — pre-existing
- `app/views/peak_flow_readings/show.html.erb` line 18 — pre-existing

**Correct class:** `.btn-delete` defined in `app/assets/stylesheets/application.css` line 771.

## Proposed Solutions

### Option A — Replace btn-danger with btn-delete in all 4 views (Recommended)

Do a targeted find-and-replace of `btn-danger` → `btn-delete` in all 4 affected view files.

**Pros:** Uses the existing, already-styled class. No CSS changes required. Consistent across all views.
**Cons:** None.
**Effort:** Very small
**Risk:** None

### Option B — Add a `.btn-danger` CSS alias

Add `.btn-danger { @extend .btn-delete }` (or duplicate the rules) to `application.css` so both class names work.

**Pros:** No view changes needed.
**Cons:** Adds a redundant CSS class. Two names for the same thing creates confusion for future developers. Does not fix the underlying inconsistency in naming.
**Effort:** Very small
**Risk:** Low — but adds technical debt

## Recommended Action

Option A — replace `btn-danger` with `btn-delete` in all 4 view files. There is no reason to keep an undefined class name when the correct one already exists and is documented in the codebase.

## Technical Details

**Affected files:**
- `app/views/settings/show.html.erb`
- `app/views/health_events/show.html.erb`
- `app/views/symptom_logs/show.html.erb`
- `app/views/peak_flow_readings/show.html.erb`

**Acceptance Criteria:**
- [ ] All delete/destroy submit buttons use `btn-delete` class
- [ ] Delete buttons render with the correct red/danger styling from `application.css`
- [ ] No `btn-danger` references remain in view files

## Work Log

- 2026-03-10: Identified by pattern-recognition-specialist in Phase 16 code review.
