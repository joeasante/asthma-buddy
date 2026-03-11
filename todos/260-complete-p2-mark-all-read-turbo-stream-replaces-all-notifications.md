---
status: pending
priority: p2
issue_id: "260"
tags: [code-review, performance, rails]
dependencies: []
---

# `mark_all_read` Turbo Stream Replaces All Notifications Including Already-Read Ones

## Problem Statement

The `mark_all_read` action loads `@notifications = Current.user.notifications.newest_first` (all notifications, including already-read ones) AFTER calling `update_all`. The Turbo Stream template then emits one `turbo_stream.replace` per notification. A user with 200 historical notifications sends 200 DOM replace operations to the browser. The scope should be captured BEFORE `update_all` runs (only the previously-unread records), so the Turbo Stream only updates the rows that actually changed state.

## Findings

`app/controllers/notifications_controller.rb` lines 26–33 and `app/views/notifications/mark_all_read.turbo_stream.erb`:

- `Current.user.notifications.unread.update_all(read: true)` marks all unread as read.
- Immediately after, `@notifications = Current.user.notifications.newest_first` loads the full notification set — all records, now all marked read.
- The Turbo Stream iterates over every notification and emits a `turbo_stream.replace` for each.
- For a user with a large notification history, this produces an unbounded number of DOM operations in a single response.

Confirmed by: kieran-rails-reviewer.

## Proposed Solutions

### Option A — Capture previously-unread records before `update_all` *(Recommended)*

```ruby
# app/controllers/notifications_controller.rb
def mark_all_read
  previously_unread = Current.user.notifications.unread.to_a
  Current.user.notifications.unread.update_all(read: true, updated_at: Time.current)
  @notifications = previously_unread
end
```

The Turbo Stream then only iterates over the records that actually changed state.

Pros: response payload is bounded to changed records only; semantically correct (only update DOM for rows that changed)
Cons: requires loading the previously-unread records into memory before the bulk update; acceptable given the bounded unread count in normal usage.

### Option B — Replace the entire notifications list container

```erb
<%# app/views/notifications/mark_all_read.turbo_stream.erb %>
<%= turbo_stream.replace "notifications-list" do %>
  <%= render @all_notifications %>
<% end %>
```

Pros: single DOM operation regardless of notification count
Cons: re-renders all notifications (still loads all records); loses the per-row granularity that Turbo Streams provide; no material improvement in record loading.

## Recommended Action

Option A — capture the previously-unread scope before `update_all`. This minimises both server-side rendering and client-side DOM operations to only the changed records.

## Technical Details

- **Affected files:**
  - `app/controllers/notifications_controller.rb` lines 26–33
  - `app/views/notifications/mark_all_read.turbo_stream.erb`

## Acceptance Criteria

- [ ] `previously_unread` is captured via `Current.user.notifications.unread.to_a` before `update_all` is called
- [ ] `@notifications` is assigned from `previously_unread`, not from a post-update full query
- [ ] The Turbo Stream template only emits replace operations for notifications that were previously unread
- [ ] A user with no unread notifications receives an empty (or minimal) Turbo Stream response
- [ ] Existing `mark_all_read` controller and system tests continue to pass

## Work Log

- 2026-03-11: Found by kieran-rails-reviewer during Phase 19 code review
