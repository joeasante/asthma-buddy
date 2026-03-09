---
status: complete
priority: p3
issue_id: "162"
tags: [uat, health-events, dashboard, chart, ui]
dependencies: []
---

# Dashboard Chart: Show Ongoing Events Strip for Events Starting Before This Week

## Problem Statement

The 7-day peak flow chart filters health event markers by `recorded_at` within
the current week window (Mon–today). Events that started before this week but
are still ongoing (e.g. an illness from 2 weeks ago) have no valid x-axis
position so they are correctly excluded from the chart markers.

However, these ongoing events are clinically relevant context — they explain
why peak flow might be lower this week. There is no visual indication of them
on the chart.

Identified during Phase 15 UAT.

## Proposed Solution

Add a thin "Active" strip below the chart x-axis labels, rendered only when
there are ongoing health events that started before the current chart window.

### Visual

```
┌─────────────────────────────────────────────────────┐
│  Peak Flow — This Week                              │
│                                                     │
│  400 ┤    ██                                        │
│  350 ┤    ██  ██                                    │
│  300 ┤    ██  ██  ██                                │
│      └──Mon─Tue─Wed─Thu─Fri─Sat─Sun                 │
│                                                     │
│  Active  ● Illness (since 25 Feb)                   │
└─────────────────────────────────────────────────────┘
```

- Only rendered when ongoing events exist that started before `week_start`
- Coloured dot per event type (same colour palette as chart markers)
- "since [date]" gives temporal context
- Multiple ongoing events shown inline:
  `● Illness (since 25 Feb)  ● Hospital visit (since 2 Mar)`

### Implementation

**`app/controllers/dashboard_controller.rb`**

Add a second query alongside `@health_event_markers`:

```ruby
@ongoing_health_events = user.health_events
  .where(recorded_at: ...week_start.beginning_of_day)
  .where(ended_at: nil)
  .where.not(event_type: HealthEvent::POINT_IN_TIME_TYPES)
  .order(recorded_at: :asc)
```

**`app/views/dashboard/index.html.erb`** (or chart partial)

Below the canvas, render the strip conditionally:

```erb
<% if @ongoing_health_events.any? %>
  <div class="chart-ongoing-strip">
    <span class="chart-ongoing-label">Active</span>
    <% @ongoing_health_events.each do |e| %>
      <span class="chart-ongoing-event chart-ongoing-event--<%= e.event_type_css_modifier %>">
        <span class="chart-ongoing-dot" aria-hidden="true"></span>
        <%= e.event_type_label %> (since <%= e.recorded_at.strftime("%-d %b") %>)
      </span>
    <% end %>
  </div>
<% end %>
```

**`app/assets/stylesheets/dashboard.css`**

Small addition for `.chart-ongoing-strip`, `.chart-ongoing-dot` (6px circle,
colour via CSS custom property matching event type).

## Acceptance Criteria

- [ ] Strip appears below chart when ongoing events exist that started before this week
- [ ] Strip does not appear when no such events exist
- [ ] Each entry shows event type label + start date
- [ ] Dot colour matches the event type colour used in chart markers
- [ ] Strip is not shown if the chart itself is not rendered (no peak flow data this week)
- [ ] `bin/rails test` passes

## Work Log

- 2026-03-09: Identified during Phase 15 UAT. User had an ongoing illness from
  before the current week — it didn't appear as a chart marker (correct) but
  there was no indication of it on the chart at all.
