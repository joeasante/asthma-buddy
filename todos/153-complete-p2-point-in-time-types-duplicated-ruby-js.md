---
status: pending
priority: p2
issue_id: "153"
tags: [code-review, javascript, stimulus, architecture, health-events]
dependencies: []
---

# `POINT_IN_TIME_TYPES` Duplicated Between Ruby Model and JavaScript

## Problem Statement

`HealthEvent::POINT_IN_TIME_TYPES` in the Ruby model and `POINT_IN_TIME_TYPES` in `end_date_controller.js` are identical arrays. There is no shared source of truth. If a new point-in-time event type is added to the enum, both files must be updated — and no test would catch if only one is updated.

## Findings

**Flagged by:** architecture-strategist (P2), pattern-recognition-specialist (P2), code-simplicity-reviewer (P2)

**Locations:**
- `app/models/health_event.rb`, line 22: `POINT_IN_TIME_TYPES = %w[gp_appointment medication_change].freeze`
- `app/javascript/controllers/end_date_controller.js`, line 10: `const POINT_IN_TIME_TYPES = ["gp_appointment", "medication_change"]`

**Impact:** The JS constant drives the duration section progressive disclosure on the form — hiding start/end fields for point-in-time event types. A new event type (e.g. `telehealth`) added as point-in-time in the Ruby model will still show duration fields on the form until someone remembers to update the JS constant.

## Proposed Solutions

### Option A — Drive JS from server-side `data-` attribute (Recommended)

Pass the Ruby constant to the form as a Stimulus value:

```erb
<%# app/views/health_events/_form.html.erb %>
<%= form_with model: health_event, id: "health_event_form",
      data: {
        turbo: true,
        controller: "end-date",
        "end-date-point-in-time-types-value": HealthEvent::POINT_IN_TIME_TYPES.to_json
      } do |form| %>
```

```javascript
// end_date_controller.js
static values = {
  pointInTimeTypes: Array
}

// Replace hardcoded constant:
get pointInTimeTypes() {
  return this.pointInTimeTypesValue
}

// In updateForEventType():
const isPointInTime = this.pointInTimeTypes.includes(value)
```

Delete the hardcoded `const POINT_IN_TIME_TYPES = [...]` line.

**Pros:** Ruby model is single source of truth. Adding a type to the enum automatically updates the form behaviour.
**Effort:** Small
**Risk:** Low

### Option B — Add a sync comment to the JS file

```javascript
// Keep in sync with HealthEvent::POINT_IN_TIME_TYPES in app/models/health_event.rb
const POINT_IN_TIME_TYPES = ["gp_appointment", "medication_change"]
```

**Pros:** Zero risk. Immediate.
**Cons:** Still two sources of truth. A comment doesn't prevent divergence.
**Effort:** Trivial
**Risk:** None

## Recommended Action

Option A for the correct fix. Option B as an immediate mitigation if Option A is deferred.

## Acceptance Criteria

- [ ] Only one place in the codebase defines which event types are point-in-time
- [ ] Adding a new event type to `HealthEvent::POINT_IN_TIME_TYPES` automatically applies to form behaviour
- [ ] `bin/rails test test/system/medical_history_test.rb` passes

## Work Log

- 2026-03-09: Identified by architecture-strategist, pattern-recognition-specialist, and code-simplicity-reviewer during `ce:review`.
