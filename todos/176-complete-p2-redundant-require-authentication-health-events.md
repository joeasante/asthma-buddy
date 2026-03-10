---
status: pending
priority: p2
issue_id: "176"
tags: [code-review, security, health-events, cleanup]
dependencies: []
---

# HealthEventsController Declares require_authentication Redundantly

## Problem Statement
HealthEventsController line 4 explicitly calls `before_action :require_authentication`. ApplicationController already includes the Authentication concern which registers this before_action for all controllers. The explicit declaration is harmless but misleading — a developer reading PeakFlowReadingsController and SymptomLogsController (which don't have it) might incorrectly conclude HealthEventsController has special authentication requirements, or that the other controllers are unprotected.

## Proposed Solutions

### Option A
Remove the redundant `before_action :require_authentication` line from HealthEventsController. Verify ApplicationController's Authentication concern sets it universally before removing.
- Effort: Small
- Risk: Low

## Recommended Action

## Technical Details
- Affected files: app/controllers/health_events_controller.rb

## Acceptance Criteria
- [ ] ApplicationController's Authentication concern is confirmed to register require_authentication for all controllers
- [ ] The redundant `before_action :require_authentication` line is removed from HealthEventsController
- [ ] Unauthenticated requests to health events actions are still rejected after the change
- [ ] No other controller has a similar redundant declaration that should be cleaned up

## Work Log
- 2026-03-10: Created via code review
