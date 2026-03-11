---
status: pending
priority: p3
issue_id: "266"
tags: [code-review, ux, rails, convention]
dependencies: []
---

# No Toast Feedback in `mark_read` and `mark_all_read` Turbo Stream Responses

## Problem Statement

The Turbo Stream responses for `mark_read` and `mark_all_read` are silent — they update the DOM but provide no toast or flash feedback to the user. Every other mutating Turbo Stream in the project includes a `turbo_stream.replace "flash-messages"` block with a toast notice. The notification mark-read actions deviate from this established UX convention.

## Findings

`app/views/notifications/mark_read.turbo_stream.erb` and `app/views/notifications/mark_all_read.turbo_stream.erb` contain no flash/toast stream.

Project-wide convention from other mutating Turbo Streams:

```erb
<%# app/views/settings/medications/destroy.turbo_stream.erb %>
<%= turbo_stream.replace "flash-messages" do %>
  <%= render "shared/flash", notice: "Medication deleted." %>
<% end %>

<%# app/views/dose_logs/destroy.turbo_stream.erb %>
<%= turbo_stream.replace "flash-messages" do %>
  <%= render "shared/flash", notice: "Dose log deleted." %>
<% end %>

<%# app/views/health_events/destroy.turbo_stream.erb %>
<%= turbo_stream.replace "flash-messages" do %>
  <%= render "shared/flash", notice: "Event deleted." %>
<% end %>

<%# app/views/settings/medications/refill.turbo_stream.erb %>
<%= turbo_stream.replace "flash-messages" do %>
  <%= render "shared/flash", notice: "Stock updated." %>
<% end %>
```

None of the notification Turbo Stream templates follow this convention.

Confirmed by: kieran-rails-reviewer.

## Proposed Solutions

### Option A — Add `turbo_stream.replace "flash-messages"` to both templates *(Recommended)*

`app/views/notifications/mark_read.turbo_stream.erb`:

```erb
<%= turbo_stream.replace "flash-messages" do %>
  <%= render "shared/flash", notice: "Notification marked as read." %>
<% end %>
<%# ... existing DOM update streams ... %>
```

`app/views/notifications/mark_all_read.turbo_stream.erb`:

```erb
<%= turbo_stream.replace "flash-messages" do %>
  <%= render "shared/flash", notice: "All notifications marked as read." %>
<% end %>
<%# ... existing DOM update streams ... %>
```

Pros: consistent with every other mutating action in the application; gives the user clear confirmation
Cons: minor — adds a small amount of template markup

## Recommended Action

Option A — add toast blocks to both Turbo Stream templates, matching the project convention exactly.

## Technical Details

- **Affected files:**
  - `app/views/notifications/mark_read.turbo_stream.erb`
  - `app/views/notifications/mark_all_read.turbo_stream.erb`

## Acceptance Criteria

- [ ] Marking a single notification as read displays a "Notification marked as read." toast
- [ ] Marking all notifications as read displays an "All notifications marked as read." toast
- [ ] The toast appears in the `flash-messages` DOM region (consistent with all other toasts)
- [ ] Existing Turbo Stream tests for mark_read and mark_all_read continue to pass

## Work Log

- 2026-03-11: Found by kieran-rails-reviewer during Phase 19 code review
