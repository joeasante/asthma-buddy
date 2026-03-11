---
phase: 19-notifications
plan: 03
completed_at: 2026-03-11T09:47:15Z
duration_seconds: 164
tasks_completed: 2
tasks_total: 2
files_created: 2
files_modified: 0
tests_added: 18
tests_total: 462
---

# Plan 19-03 Summary: Notification Tests

## Objective

Write controller integration tests and system tests for the full notification lifecycle: feed scoping, mark-read, mark-all-read, cross-user isolation, unauthenticated guards, unread badge visibility, and empty state.

## Tasks Completed

### Task 1: Controller integration tests for NotificationsController

**Status:** Complete (commit cffc391)

Created `test/controllers/notifications_controller_test.rb` with 11 integration test cases covering the full NotificationsController surface:

- **index**: 200 for authenticated user, user-scoped listing (Alice's body present, Bob's absent), unauthenticated redirect
- **mark_read**: marks notification read on success, returns Turbo Stream content-type, returns 404 for cross-user notification, unauthenticated redirect
- **mark_all_read**: marks all unread as read (verified via count), returns Turbo Stream content-type, preserves other users' notification state, unauthenticated redirect

Followed the `health_events_controller_test.rb` pattern: `ActionDispatch::IntegrationTest`, `SessionTestHelper` `sign_in_as`/`sign_out`, fixture references.

### Task 2: System tests for notifications UI interactions

**Status:** Complete (commit affe8c3)

Created `test/system/notifications_test.rb` with 7 Capybara system test cases:

- **Badge visibility**: `[data-unread-count]:not([data-unread-count='0'])` selector confirms badge appears on nav bell when unread notifications exist
- **Badge resets after mark all read**: `#nav-bell[data-unread-count='0']` confirmed via Turbo Stream replace of nav-bell partial
- **Mark single inline**: `within("##{dom_id(@low_stock_notif)}")` → click "Mark read" → asserts no `.notification-unread-dot` and no `.notification-body--unread` in that row
- **Mark all read**: `.notification-row--unread` minimum: 2 before, zero after clicking "Mark all read"
- **Empty state (all read)**: `update_all(read: true)` then visit → `assert_text "You're all caught up."`
- **Empty state (no notifications)**: `destroy_all` then visit → `assert_text "You're all caught up."`
- **Regression: Medications in desktop header**: `header a[href*='settings/medications']` still present

## Files Created

| File | Purpose |
|------|---------|
| `test/controllers/notifications_controller_test.rb` | 11 controller integration tests: index, mark_read, mark_all_read — scoping, Turbo Stream, cross-user isolation, unauthenticated |
| `test/system/notifications_test.rb` | 7 system tests: badge visibility, mark single inline, mark all read, empty states (2 cases), regression check |

## Files Modified

None.

## Key Decisions

1. **`@user.notifications.unread.count` without reload**: In controller tests, `update_all` invalidates the cache automatically for the count query — no explicit `.reload` needed on the association proxy; calling `.count` fires a fresh SQL query.

2. **System test inline notification creates**: Created `@low_stock_notif` and `@missed_dose_notif` inline in setup rather than relying solely on fixtures. This gives deterministic DOM IDs for `within("##{dom_id(@low_stock_notif)}")` selector patterns — fixtures have known names but the system test needs the actual AR ID.

3. **`assert_selector "[data-unread-count]:not([data-unread-count='0'])"` for badge**: Both the desktop `#nav-bell` and the bottom nav Alerts link carry `data-unread-count` and `has-unread-badge`. This selector catches either element without needing to know which is currently visible given viewport size.

4. **`assert_text "You're all caught up."` covers both empty states**: The view renders it in two places: `empty-state-headline` (when `@notifications.empty?`) and `notifications-all-read` paragraph (when `@notifications.all?(&:read)`). Single `assert_text` assertion works for both.

5. **Pre-existing system test failures confirmed not regressions**: Running `bin/rails test:system` showed failures in HomeTest, OnboardingTest, MedicationManagementTest, MedicalHistoryTest — all pre-existing. Notifications system tests pass cleanly when run in isolation.

## Capybara Gotchas

- **`wait: 5` on all Turbo Stream assertions**: Default 2s wait was insufficient; all post-interaction assertions use `wait: 5`
- **`within("##{dom_id(@low_stock_notif)}")` uses inline-created notification ID**: Fixture-based IDs would require `ActiveRecord::FixtureSet.identify` which is less readable; inline creation gives a real AR ID
- **`assert_no_selector` not `assert_no_text` for CSS class checks**: Unread dot (`.notification-unread-dot`) and bold body (`.notification-body--unread`) are DOM elements, not text — `assert_no_selector` is appropriate

## Test Results

- Tests added: 18 (11 controller + 7 system)
- Total integration tests: 462 (up from 451 at Phase 19-02 close)
- System tests (notifications only): 7 runs, 18 assertions, 0 failures, 0 errors
- Full integration suite: 462 runs, 1208 assertions, 0 failures, 0 errors, 0 skips
- Regressions: 0

## Commits

| Hash | Description |
|------|-------------|
| cffc391 | test(19-03): controller integration tests for NotificationsController |
| affe8c3 | test(19-03): system tests for notifications UI interactions |

## Self-Check: PASSED

- `test/controllers/notifications_controller_test.rb` verified present
- `test/system/notifications_test.rb` verified present
- Both task commits (cffc391, affe8c3) verified in git log
- 462 integration tests passing, 0 regressions
- 7 notification system tests passing in isolation

---
*Phase: 19-notifications*
*Completed: 2026-03-11*
