---
status: complete
priority: p2
issue_id: "276"
tags: [code-review, rails, dry, health-events, charts, pattern]
dependencies: []
---

# Health event marker building duplicated with subtle inconsistency

## Problem Statement

`@health_event_markers` is built with nearly identical `.map` blocks in two separate controllers. The blocks produce the same hash shape (`date`, `type`, `label`, `css_modifier`, optional `end_date`). However there is a **subtle functional inconsistency**: the Dashboard version checks `!e.point_in_time?` before adding `end_date`, but the PeakFlowReadings version does not. This means point-in-time events (GP appointments, medication changes) could erroneously get an `end_date` in the peak flow view.

## Findings

- **Dashboard** (`app/controllers/dashboard_controller.rb:72–83`):
  ```ruby
  marker[:end_date] = e.ended_at.to_date.to_s if !e.point_in_time? && e.ended_at.present?
  ```

- **PeakFlowReadings** (`app/controllers/peak_flow_readings_controller.rb:113–120`):
  ```ruby
  marker[:end_date] = e.ended_at.to_date.to_s if e.ended_at.present?
  ```

Point-in-time events (`gp_appointment`, `medication_change`) have no `ends_on` in practice — but the data model doesn't prevent it. If a point-in-time event somehow had `ended_at` set, the peak flow chart would render an incorrect duration span.

- **Agents:** architecture-strategist, pattern-recognition-specialist, code-simplicity-reviewer

## Proposed Solutions

### Option A — Add `to_chart_marker` to `HealthEvent` model (Recommended)

```ruby
# app/models/health_event.rb
def to_chart_marker
  marker = {
    date:         recorded_at.to_date.to_s,
    type:         event_type,
    label:        chart_label,
    css_modifier: event_type_css_modifier
  }
  marker[:end_date] = ended_at.to_date.to_s if !point_in_time? && ended_at.present?
  marker
end
```

Both controllers reduce to: `events.map(&:to_chart_marker)`

**Pros:** Single definition. Bug fix (adds back the `point_in_time?` guard). Consistent with `chart_label` and `event_type_css_modifier` already on the model. Future chart consumers get it for free.
**Cons:** None.
**Effort:** Small
**Risk:** Low

### Option B — Extract to a shared concern or helper

**Pros:** Keeps model lean.
**Cons:** Over-engineered when the model already has chart-related methods.
**Effort:** Small
**Risk:** Low

## Recommended Action

Option A — model method. The model already has `chart_label` and `event_type_css_modifier`; `to_chart_marker` is the natural completion of that pattern.

## Technical Details

- **Affected files:**
  - `app/models/health_event.rb` — add `to_chart_marker`
  - `app/controllers/dashboard_controller.rb` — use `.map(&:to_chart_marker)`
  - `app/controllers/peak_flow_readings_controller.rb` — use `.map(&:to_chart_marker)`
  - `test/models/health_event_test.rb` — add test for `to_chart_marker`

## Acceptance Criteria

- [ ] `HealthEvent#to_chart_marker` method added to model
- [ ] Both controllers use `.map(&:to_chart_marker)`
- [ ] Point-in-time events do NOT get `end_date` in either chart
- [ ] Model test covers `to_chart_marker` for all event types

## Work Log

- 2026-03-11: Identified by architecture-strategist, pattern-recognition-specialist during code review of dev branch
