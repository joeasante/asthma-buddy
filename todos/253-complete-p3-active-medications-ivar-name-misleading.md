---
status: pending
priority: p3
issue_id: "253"
tags: [code-review, naming, rails, readability]
dependencies: []
---

# `@active_medications` Ivar Name Is Conceptually Misleading

## Problem Statement

`@active_medications` in `MedicationsController#index` contains all non-archived medications — regular medications (not courses) plus active courses. It does not match the `active_courses` model scope. A future developer correlating the ivar to the scope will be misled: `active_courses` is a subset of `@active_medications`, not the full set.

The asymmetry is also visible in the paired ivars:
- `@active_medications` — untyped, broad ("all visible medications")
- `@archived_courses` — typed, narrow ("only archived course records")

They are partitions of the same collection but named at different levels of abstraction.

## Findings

`app/controllers/settings/medications_controller.rb` line 9:
```ruby
@active_medications  = all_medications.reject { |m| m.course? && !m.course_active? }
```

This contains: all regular medications (course: false) + active courses. Not "active medications" in the sense of the model scope.

Confirmed by: pattern-recognition-specialist.

## Proposed Solutions

### Option A — Rename to `@visible_medications` *(Recommended)*

Conveys "everything the user sees in the active list" without implying a scope relation.

### Option B — Rename to `@current_medications`

Conveys "currently active, not expired" which matches the UX concept better than "active".

## Recommended Action

Option A — `@visible_medications`. Update in controller, views, and tests.

## Technical Details

- **Files to update:**
  - `app/controllers/settings/medications_controller.rb`
  - `app/views/settings/medications/index.html.erb` (2 references)
  - `test/controllers/settings/medications_controller_test.rb` (if assigns are used in tests)

## Acceptance Criteria

- [ ] `@active_medications` renamed to `@visible_medications` in controller, views, and tests
- [ ] No functional change
- [ ] All tests pass

## Work Log

- 2026-03-10: Found by pattern-recognition-specialist during Phase 18 code review
