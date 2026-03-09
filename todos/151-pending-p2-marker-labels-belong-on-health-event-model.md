---
status: pending
priority: p2
issue_id: "151"
tags: [code-review, rails, architecture, health-events, dashboard]
dependencies: []
---

# `MARKER_LABELS`/`event_marker_label` Belong on `HealthEvent`, Not `DashboardController`

## Problem Statement

`DashboardController` contains a `MARKER_LABELS` constant and an `event_marker_label` private helper that produce short-form labels for `HealthEvent` types (e.g. "GP", "Ill", "Rx"). This is domain knowledge about how a `HealthEvent` represents itself in a compact context — it belongs on the model, alongside `TYPE_LABELS` and `event_type_label`. The controller placement violates Single Responsibility and creates a second owner of HealthEvent display logic.

## Findings

**Flagged by:** kieran-rails-reviewer (P2), architecture-strategist (P2)

**Location:** `app/controllers/dashboard_controller.rb`, ~lines 73–83

**Current code:**
```ruby
private

MARKER_LABELS = {
  "hospital_visit"    => "Hosp",
  "gp_appointment"    => "GP",
  "illness"           => "Ill",
  "medication_change" => "Rx",
  "other"             => "Evt"
}.freeze

def event_marker_label(event)
  MARKER_LABELS[event.event_type] || "Evt"
end
```

**Problems:**
1. `private` does not scope constants in Ruby — `MARKER_LABELS` is accessible as `DashboardController::MARKER_LABELS`. It misleads readers and generates Ruby warnings in future versions.
2. Any future consumer of chart labels (PDF export, API endpoint, second chart) must either duplicate the hash or import from `DashboardController`.
3. The model already has `TYPE_LABELS` — two constants on two classes for the same concept.

## Proposed Solutions

### Option A — Move to `HealthEvent` model (Recommended)
```ruby
# app/models/health_event.rb
CHART_LABELS = {
  "hospital_visit"    => "Hosp",
  "gp_appointment"    => "GP",
  "illness"           => "Ill",
  "medication_change" => "Rx",
  "other"             => "Evt"
}.freeze

def chart_label
  CHART_LABELS.fetch(event_type, "Evt")
end
```

Then in `DashboardController`:
```ruby
@health_event_markers = user.health_events
  .where(...)
  .map { |e| { date: ..., type: e.event_type, label: e.chart_label, css_modifier: e.event_type_css_modifier } }
```

Remove `MARKER_LABELS` and `event_marker_label` from `DashboardController`.

**Pros:** Single owner for all HealthEvent label logic. Model is self-contained. No logic change.
**Effort:** Small
**Risk:** None

## Acceptance Criteria

- [ ] `HealthEvent::CHART_LABELS` (or equivalent) exists in `app/models/health_event.rb`
- [ ] `HealthEvent#chart_label` instance method returns abbreviated label
- [ ] `DashboardController` has no `MARKER_LABELS` constant or `event_marker_label` method
- [ ] `bin/rails test test/controllers/dashboard_controller_test.rb` passes
- [ ] `bin/rails test` passes

## Work Log

- 2026-03-09: Identified by kieran-rails-reviewer and architecture-strategist during `ce:review`.
