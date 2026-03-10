---
status: pending
priority: p2
issue_id: "152"
tags: [code-review, rails, turbo-streams, ux, health-events]
dependencies: []
---

# Turbo Stream Destroy Orphans Month Headings and Loses Empty State

## Problem Statement

`destroy.turbo_stream.erb` only removes the individual event row (`turbo_stream.remove dom_id(@health_event)`). It does nothing about the month heading (`<h3>`) that groups events by month, or about restoring the empty state when the last event is deleted. After the last event in a month group is removed, its heading remains as a visible orphan. After the very last event on the page is deleted, the user sees a blank card with no empty-state guidance.

## Findings

**Flagged by:** kieran-rails-reviewer (P2), architecture-strategist (P2)

**Location:**
- `app/views/health_events/destroy.turbo_stream.erb` — only removes event row
- `app/views/health_events/index.html.erb` — month `<h3>` headings sit as siblings of event rows, not inside turbo frames

**What happens:**
1. Month with 1 event → user deletes it → `<h3>March 2026</h3>` remains with no events below it
2. Last event on page → deleted → `#health_events_list` has only an orphan heading, no empty-state div
3. The index view comment acknowledges the `#health_events_list` always renders (correct), but does not address the heading orphan

**Root cause:** Month headings have no identifiable turbo frame or wrapping element — they cannot be selectively removed from a Turbo Stream response.

## Proposed Solutions

### Option A — Replace entire `#health_events_list` after destroy (Recommended)
After removing the event, re-render the entire list from the controller:

```ruby
# In HealthEventsController#destroy respond_to turbo_stream block:
format.turbo_stream do
  events = Current.user.health_events.includes(:rich_text_notes).recent_first.to_a
  grouped = events.group_by { |e| e.recorded_at.beginning_of_month }
  render turbo_stream: [
    turbo_stream.replace("health_events_list") do
      render partial: "health_events/list", locals: { grouped_events: grouped }
    end,
    turbo_stream.replace("flash-messages") { ... }
  ]
end
```

Extract list rendering into a `_list.html.erb` partial.

**Pros:** Always correct. Empty state and headings handled automatically. Simple.
**Cons:** Slightly larger response payload.
**Effort:** Small–Medium
**Risk:** Low

### Option B — Wrap month groups in identifiable elements
Wrap each month group in `<div id="events-month-<%= month_start.strftime('%Y-%m') %>">`. Add a second `turbo_stream.remove` in the destroy stream if the deleted event was the last in its month.

**Pros:** More surgical.
**Cons:** More logic in controller/template to detect "last event in group". Higher complexity.
**Effort:** Medium
**Risk:** Medium (edge cases)

## Recommended Action

Option A. Simple, correct, and the `_list.html.erb` partial has other reuse value (e.g. search/filter responses).

## Acceptance Criteria

- [ ] Deleting the last event in a month group removes the month heading too
- [ ] Deleting the last event on the page shows the empty state
- [ ] System test covers "delete last event → empty state appears"
- [ ] `bin/rails test` passes

## Work Log

- 2026-03-09: Identified by kieran-rails-reviewer and architecture-strategist during `ce:review`.
