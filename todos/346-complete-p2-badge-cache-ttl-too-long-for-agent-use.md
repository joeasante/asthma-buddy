---
status: pending
priority: p2
issue_id: "346"
tags: [code-review, caching, agent-native, performance]
dependencies: []
---

# Badge count cache TTL of 1 hour produces stale counts for agents and rapid users

## Problem Statement

`ApplicationController#set_notification_badge_count` uses `expires_in: 1.hour`. The badge cache is invalidated on `after_commit` callbacks (create, mark-as-read) but NOT on the `mark_all_read` path (handled by explicit delete in the controller) and NOT on `PruneNotificationsJob` (which only deletes already-read notifications so this is a non-issue).

The 1-hour TTL is a safety net — if an invalidation is missed, the badge will be stale for up to 1 hour. This is a long window for:
- **Agents**: An agent that calls `POST /notifications/:id/mark_read.json` and then checks the badge count via `GET /dashboard.json` will see the pre-update count for up to 1 hour if the after_commit callback fires but the badge cache already has the right value... actually the after_commit fires and deletes the cache key, so the next request recomputes. The 1h TTL mainly affects the window where a missed invalidation causes stale data.
- **Rapid navigation**: A user who receives a new notification and navigates to the dashboard within the TTL window (before the after_commit fires in an edge case) sees the old count.

The dashboard vars cache uses 5 minutes — the badge cache at 1 hour is 12x longer for no stated reason.

## Proposed Solutions

### Option A: Reduce TTL to 5 minutes (matches dashboard)
```ruby
Rails.cache.fetch(Notification.badge_cache_key(Current.user.id), expires_in: 5.minutes) do
```
- **Pros:** Consistent with dashboard TTL; stale data window reduced from 1h to 5min
- **Cons:** 12x more cache misses — but the badge query is a single indexed COUNT(*), cheapest possible query
- **Effort:** Small
- **Risk:** Low

### Option B: Keep 1 hour
The after_commit callbacks invalidate on every write. The 1h TTL is only hit if a callback is missed (e.g., process crash between write and commit). Rare.
- **Effort:** None
- **Risk:** Low (operational)

## Recommended Action

Option A. The badge query is trivially cheap (indexed COUNT on a small user-scoped table). The consistency with the dashboard TTL is worth more than the marginal cache efficiency.

## Technical Details

**Affected files:**
- `app/controllers/application_controller.rb`

## Acceptance Criteria

- [ ] `expires_in: 1.hour` changed to `expires_in: 5.minutes`
- [ ] BadgeCacheTest still passes

## Work Log

- 2026-03-13: Identified in Phase 22 code review (agent-native-reviewer)
