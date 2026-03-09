---
status: pending
priority: p2
issue_id: "161"
tags: [uat, health-events, ui, display]
dependencies: []
---

# Duration Events: Show Time Component and Calculated Duration

## Problem Statement

Duration health events (illness, hospital visit, other) currently display
only the date portion of `recorded_at` and `ended_at` — the time is stripped.
For hospital visits especially, admission and discharge times are clinically
meaningful. A calculated duration (e.g. "3 days 4 hrs") would also help users
quickly understand length of stay or illness episode without manual arithmetic.

Identified during Phase 15 UAT.

## Proposed Display

| Type | Current | Proposed |
|------|---------|----------|
| Point-in-time (GP, Rx change) | `14 Feb 2026, 10:30` | unchanged ✓ |
| Duration — ongoing | `14 Feb 2026 · Ongoing` | `14 Feb 2026, 10:30 · Ongoing` |
| Duration — resolved | `14 Feb 2026 – 17 Feb 2026` | `14 Feb 2026, 10:30 – 17 Feb 2026, 15:00 · 3 days 4 hrs` |

## Fix

### `app/views/health_events/_event_row.html.erb`

Change duration display branches:

```erb
<%# Resolved duration event — show datetime range + calculated duration %>
<% elsif health_event.ended_at.present? %>
  <span class="event-row-time">
    <time datetime="<%= health_event.recorded_at.iso8601 %>"><%= health_event.recorded_at.strftime("%-d %b %Y, %H:%M") %></time>
    <span aria-hidden="true">–</span>
    <time datetime="<%= health_event.ended_at.iso8601 %>"><%= health_event.ended_at.strftime("%-d %b %Y, %H:%M") %></time>
    <span class="event-row-duration"><%= health_event.formatted_duration %></span>
  </span>
<%# Ongoing duration event — show start datetime %>
<% else %>
  <time class="event-row-time" datetime="<%= health_event.recorded_at.iso8601 %>">
    <%= health_event.recorded_at.strftime("%-d %b %Y, %H:%M") %>
  </time>
  <span class="event-ongoing-badge">Ongoing</span>
<% end %>
```

### `app/models/health_event.rb`

Add `formatted_duration` helper:

```ruby
def formatted_duration
  return unless ended_at.present? && recorded_at.present?
  total_seconds = (ended_at - recorded_at).to_i
  days  = total_seconds / 86_400
  hours = (total_seconds % 86_400) / 3_600
  if days > 0
    hours > 0 ? "#{days}d #{hours}h" : "#{days}d"
  else
    "#{hours}h"
  end
end
```

## Acceptance Criteria

- [ ] Resolved duration events show start and end as `%-d %b %Y, %H:%M`
- [ ] Resolved duration events show calculated duration (e.g. "3d 4h", "9d", "6h")
- [ ] Ongoing duration events show start as `%-d %b %Y, %H:%M`
- [ ] Point-in-time events unchanged
- [ ] `bin/rails test` passes

## Work Log

- 2026-03-09: Identified during Phase 15 UAT. User noted hospital visit times
  are clinically meaningful; duration calculation also useful for illness episodes.
