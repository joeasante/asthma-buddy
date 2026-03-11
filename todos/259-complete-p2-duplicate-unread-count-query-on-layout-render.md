---
status: pending
priority: p2
issue_id: "259"
tags: [code-review, performance, rails]
dependencies: []
---

# Duplicate Unread COUNT Query on Every Authenticated Page Render

## Problem Statement

Two separate `Current.user.notifications.unread.count` SQL queries fire on every authenticated page render — one for the desktop nav bell (`application.html.erb`) and one for the bottom nav badge (`_bottom_nav.html.erb`). These are independent queries even though they return the same value. Every page load for an authenticated user costs 2 COUNT queries for the same data. The fix is a `before_action` in `ApplicationController` setting `@unread_notification_count` once, then both partials read from that ivar.

## Findings

`app/views/layouts/application.html.erb` line 73 and `app/views/layouts/_bottom_nav.html.erb` line 43 each call `Current.user.notifications.unread.count` independently.

- Both calls execute against the same user and the same scope.
- Both calls fire on every authenticated page render, including Turbo Frame partial renders where the layout is still evaluated.
- No memoisation or controller-level assignment exists to deduplicate these queries.

Confirmed by: kieran-rails-reviewer.

## Proposed Solutions

### Option A — `before_action` in `ApplicationController` *(Recommended)*

```ruby
# app/controllers/application_controller.rb
before_action :set_notification_badge_count, if: :authenticated?

private

  def set_notification_badge_count
    @unread_notification_count = Current.user.notifications.unread.count
  end
```

Then replace both inline query calls in the layout partials:

```erb
<%# app/views/layouts/application.html.erb %>
<%= @unread_notification_count %>

<%# app/views/layouts/_bottom_nav.html.erb %>
<%= @unread_notification_count %>
```

Pros: single query per request, no view logic change beyond reading an ivar, consistent value guaranteed between both nav elements.
Cons: none — the ivar is set before any view rendering begins.

### Option B — Fragment cache the count

Cache `Current.user.notifications.unread.count` with a short TTL (e.g. 30 seconds). Requires cache invalidation on `mark_read` and `mark_all_read`.

Pros: reduces DB load further for high-traffic scenarios
Cons: stale badge count for up to TTL; adds cache invalidation complexity not justified at current scale.

## Recommended Action

Option A — `before_action` in `ApplicationController`. Straightforward, zero-staleness, removes the duplicate query entirely.

## Technical Details

- **Affected files:**
  - `app/views/layouts/application.html.erb` line 73
  - `app/views/layouts/_bottom_nav.html.erb` line 43
  - `app/controllers/application_controller.rb` (add `before_action`)

## Acceptance Criteria

- [ ] `ApplicationController` defines `set_notification_badge_count` called via `before_action` when authenticated
- [ ] `@unread_notification_count` is set to `Current.user.notifications.unread.count` in that callback
- [ ] Both layout partials read `@unread_notification_count` instead of calling `Current.user.notifications.unread.count` directly
- [ ] Only one COUNT query for unread notifications fires per page render (verifiable via query log or `assert_queries` in tests)
- [ ] Existing notification badge tests continue to pass

## Work Log

- 2026-03-11: Found by kieran-rails-reviewer during Phase 19 code review
