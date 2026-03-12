---
status: diagnosed
phase: 19-notifications
source: 19-01-SUMMARY.md, 19-02-SUMMARY.md, 19-03-SUMMARY.md
started: 2026-03-11T11:00:00Z
updated: 2026-03-11T11:00:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Nav bell shows unread badge
expected: Visit any page while signed in with unread notifications. The bell icon in the top navigation bar should display a small red dot badge. The dot should sit in the upper-right corner of the bell icon.
result: pass

### 2. Mobile Alerts tab in bottom nav
expected: On a mobile viewport, the bottom navigation bar should have an "Alerts" tab with a bell icon (replacing the old Medications tab). When unread notifications exist, the Alerts tab should also show the same red dot badge.
result: pass

### 3. Notification feed lists notifications
expected: Navigate to /notifications. You should see a list of notifications, newest first. Each row should show: a type icon (warning triangle for low stock, clock for missed dose), the notification body text in bold if unread, a small blue unread dot on the right, a relative timestamp ("X minutes ago"), and a "Mark read" button.
result: pass

### 4. Low-stock notification created when dose logged
expected: With a medication that has fewer than 14 days of supply remaining, log a dose from the medication settings page. Then visit /notifications — a new low-stock notification should appear: "Ventolin has fewer than 14 days of supply remaining. Consider requesting a refill." (medication name will vary). The notification should be bold and have an unread dot.
result: pass

### 5. Mark single notification as read inline
expected: On the /notifications page, click "Mark read" on one unread notification. Without a full page reload, that single row should update inline: the unread dot disappears, the body text becomes normal weight (not bold), and the nav bell badge count decrements. Other notifications remain unchanged.
result: pass

### 6. Mark all read clears badge
expected: On the /notifications page, click "Mark all read". All notification rows should update inline (no full page reload) — unread dots disappear, body text becomes normal weight. The nav bell red dot badge should disappear. The "Mark all read" button should no longer be visible.
result: pass

### 7. Empty state when all notifications read
expected: After marking all notifications as read (or if there are no notifications), the /notifications page should show: a bell icon, "You're all caught up." as the headline, and "No notifications at the moment." as the description. The notification list and "Mark all read" button should not be visible.
result: issue
reported: "No bell icon visible. You're all caught up is visible, but doesn't exactly stand out, so could be easily missed. And it is at the bottom of the page. There is no sign of 'No notifications at the moment'. Can the header be adjusted to be more like the other headers where it has some useful information above the heading?"
severity: minor

### 8. Mark read navigates to relevant record
expected: Click "Mark read" on a low-stock notification. After the Turbo Stream update marks it as read, clicking on the notification row (or having been redirected — the row should now be in a "read" state) — specifically, the HTML fallback for mark_read (non-Turbo) should redirect to the Medications settings page. Test by opening the mark-read URL directly without Turbo: confirm the page redirects to /settings/medications.
result: skipped
reason: Edge case HTML fallback — Turbo Stream path already verified in test 5

### 9. Medications still accessible in desktop nav
expected: On a desktop viewport, the top navigation bar should still include a "Medications" link pointing to /settings/medications. This confirms the bottom nav Medications tab replacement did not remove the desktop nav link.
result: issue
reported: "The bell icon is already visible on mobile in the top nav (nav-bell class is not hidden by the .nav-link CSS rule). The Alerts bottom nav tab is therefore redundant, and Medications was removed unnecessarily. Medications should be restored to the bottom nav and the Alerts tab removed."
severity: major

## Summary

total: 9
passed: 6
issues: 2
pending: 0
skipped: 1

## Gaps

- truth: "When all notifications are read, the page shows a visually prominent all-caught-up state (bell icon, headline, description) and a descriptive page header"
  status: failed
  reason: "User reported: No bell icon visible. You're all caught up is visible, but doesn't exactly stand out, so could be easily missed. And it is at the bottom of the page. There is no sign of 'No notifications at the moment'. Can the header be adjusted to be more like the other headers where it has some useful information above the heading?"
  severity: minor
  test: 7
  root_cause: "The empty-state block (bell SVG + headline + description) only renders when @notifications.empty? — when all notifications are read but still exist, the view falls into the else branch and shows only a bare .notifications-all-read paragraph at the bottom of the list with no icon and minimal visual weight"
  artifacts:
    - path: "app/views/notifications/index.html.erb"
      issue: "all-read fallback is a bare <p class='notifications-all-read'> with no icon or description; page-header has no subtitle"
  missing:
    - "Replace bare .notifications-all-read paragraph with .empty-state block (bell SVG + headline + description) when @unread_count.zero? && @notifications.any?"
    - "Add page header subtitle beneath <h1> (e.g. 'Stay on top of your medication reminders and alerts.')"
  debug_session: ""

- truth: "The bottom nav on mobile retains the Medications tab; the bell icon in the top nav provides notification access without a redundant Alerts tab"
  status: failed
  reason: "User reported: The bell icon is already visible on mobile in the top nav (nav-bell class is not hidden by the .nav-link CSS rule). The Alerts bottom nav tab is therefore redundant, and Medications was removed unnecessarily. Medications should be restored to the bottom nav and the Alerts tab removed."
  severity: major
  test: 9
  root_cause: "Mobile CSS rule targets only .nav-auth > .nav-link elements — the .nav-bell partial uses class nav-bell (not nav-link) so it is never hidden on mobile, making the bottom-nav Alerts tab a duplicate entry point while Medications has no mobile route at all"
  artifacts:
    - path: "app/views/layouts/_bottom_nav.html.erb"
      issue: "Alerts tab replaced Medications tab; should be reversed — Medications restored, Alerts tab removed"
    - path: "app/assets/stylesheets/application.css"
      issue: ".nav-auth > .nav-link rule (line ~2186) does not hide .nav-bell — bell remains visible on mobile"
  missing:
    - "Restore Medications tab (settings_medications_path) as the 5th bottom nav tab"
    - "Remove redundant Alerts (notifications_path) tab from bottom nav"
  debug_session: ""
