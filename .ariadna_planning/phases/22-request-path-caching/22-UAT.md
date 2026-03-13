---
status: complete
phase: 22-request-path-caching
source: [22-01-SUMMARY.md, 22-02-SUMMARY.md]
started: 2026-03-13T11:00:00Z
updated: 2026-03-13T11:30:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Badge count shows unread notifications
expected: Navigate to any authenticated page (e.g. /dashboard). If you have unread notifications, a red dot/badge appears on the bell icon in the nav (desktop) or on the Alerts tab (mobile). The badge accurately reflects the current unread count.
result: pass
note: "Alerts tab removed from mobile bottom nav — bell icon in top nav handles notifications on all viewports"

### 2. Badge clears after marking all read
expected: On the /notifications page, click "Mark all read". The badge on the bell icon disappears (count drops to zero). Navigating to another page — the badge remains gone.
result: issue
reported: "badge icon disappeared, but reappeared when i went to other pages"
severity: major

### 3. Dashboard adherence indicator updates after logging a dose
expected: On the dashboard, note the adherence status for a preventer medication (e.g. "0 / 2 taken"). Go to Settings > Medications, log a dose for that preventer. Return to the dashboard — the adherence indicator should now show the updated count (e.g. "1 / 2 taken"), not the stale cached value.
result: skipped
reason: "User questioned dose logging being in Settings — captured as UX todo (2026-03-13-reconsider-dose-logging-ux-location.md)"

### 4. Dashboard reliever info reflects current state
expected: The dashboard Medications section (low stock warnings) and any reliever-related data shown on the dashboard should be current — logging a dose or triggering a refill in Settings and returning to the dashboard should show the updated state, not stale data.
result: pass

## Summary

total: 4
passed: 2
issues: 1
pending: 0
skipped: 1

## Gaps

- truth: "Badge on bell icon stays gone after marking all notifications as read"
  status: failed
  reason: "User reported: badge icon disappeared, but reappeared when i went to other pages"
  severity: major
  test: 2
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""
