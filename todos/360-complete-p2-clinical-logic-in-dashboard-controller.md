---
status: complete
priority: p2
issue_id: 360
tags: [code-review, architecture, clinical]
dependencies: []
---

## Problem Statement

Clinical interpretation logic (zone-based messaging, GINA language) is a private controller method (`build_week_interpretation`). It cannot be unit tested without integration tests. Reliever dose counting logic is also duplicated between DashboardController and AppointmentSummariesController.

## Findings

In `app/controllers/dashboard_controller.rb`, the private method `build_week_interpretation` contains clinical interpretation logic including zone-based messaging and GINA-aligned language. This logic is untestable in isolation — it can only be exercised through controller/integration tests.

Additionally, reliever dose counting logic is duplicated between:
- `app/controllers/dashboard_controller.rb`
- `app/controllers/appointment_summaries_controller.rb`

This duplication means clinical logic changes must be made in two places, risking inconsistency.

## Proposed Solutions

**A) Extract to a `WeekInterpretation` plain Ruby object**
- Pros: Independently unit-testable; reusable across controllers; clear single responsibility; can be composed into other services
- Cons: New file/class to maintain

**B) Extract to a model concern on User**
- Pros: Keeps it in the model layer; accessible from any context with a user reference
- Cons: Concerns can become bloated; clinical logic may not belong on the User model

## Recommended Action



## Technical Details

**Affected files:**
- `app/controllers/dashboard_controller.rb`
- `app/controllers/appointment_summaries_controller.rb`

## Acceptance Criteria

- [ ] Clinical logic is independently unit-testable
- [ ] No duplication of reliever dose counting
