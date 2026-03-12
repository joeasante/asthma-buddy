---
status: complete
priority: p3
issue_id: "283"
tags: [code-review, rails, performance, notifications, database]
dependencies: []
---

# Extra DB query in `NotificationsController#mark_all_read`

## Problem Statement

`NotificationsController#mark_all_read` issues a `bulk_mark_read!` call and then queries for `@notifications.first` to determine the user's locale for the flash message (or similar). Since `@notifications` is already loaded in the before-action, calling `.first` on an ActiveRecord relation that is not yet loaded fires an additional `SELECT … LIMIT 1` query. The already-loaded collection can be accessed directly.

## Findings

- **File:** `app/controllers/notifications_controller.rb` — `#mark_all_read` action
- **Agent:** performance-oracle, code-simplicity-reviewer

## Proposed Solutions

### Option A — Use `@notifications.first` on the already-loaded array (Recommended)

If `@notifications` is an Array after the before-action loads it (e.g. via `.to_a` or `.load`), calling `.first` is O(1) with no DB hit. Ensure the before-action ends with `.load` or `.to_a`.

**Pros:** Eliminates one round-trip per mark-all-read action.
**Effort:** Trivial
**Risk:** None

### Option B — Leave as-is

**Pros:** No change.
**Cons:** Unnecessary query on every mark-all-read action.
**Effort:** None
**Risk:** None (performance only)

## Recommended Action

Option A.

## Technical Details

- **Affected file:** `app/controllers/notifications_controller.rb`

## Acceptance Criteria

- [ ] `mark_all_read` does not fire an extra `SELECT … LIMIT 1` query
- [ ] Behaviour and flash message unchanged

## Work Log

- 2026-03-11: Identified by performance-oracle during code review of dev branch
