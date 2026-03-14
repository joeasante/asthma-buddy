---
status: complete
priority: p2
issue_id: 354
tags: [code-review, architecture, rails]
dependencies: []
---

## Problem Statement

The `AppointmentSummariesController#show` action is a ~50-line god action with 15+ instance variables across 6 data domains. This violates SRP and makes the action hard to test, extend, or add JSON support to.

## Findings

The show action in `app/controllers/appointment_summaries_controller.rb` runs ~12 separate database queries and assigns 15+ instance variables spanning peak flow, symptoms, reliever use, medications, courses, and health events. This makes the controller action difficult to test in isolation, hard to extend with new data domains, and impractical to add JSON rendering to without duplicating all the variable assignments.

## Proposed Solutions

**A) Extract to a `HealthReportPresenter` that encapsulates all queries**
- Pros: Clean separation; easily testable with unit tests; enables JSON rendering via `to_json`; single object to pass to views
- Cons: New pattern to introduce if no presenters exist yet

**B) Extract to a `ReportVariables` concern similar to `DashboardVariables`**
- Pros: Follows existing pattern already used in the codebase
- Cons: Concerns can become dumping grounds; harder to test than a plain Ruby object

**C) Leave as-is and add a comment**
- Pros: No code change
- Cons: Not recommended for long-term maintainability; blocks JSON API support

## Recommended Action



## Technical Details

**Affected files:**
- `app/controllers/appointment_summaries_controller.rb`

## Acceptance Criteria

- [ ] Controller action is under 10 lines
- [ ] Query logic is in a presenter or concern
- [ ] All existing tests still pass
