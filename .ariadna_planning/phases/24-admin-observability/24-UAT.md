---
status: complete
phase: 24-admin-observability
source: [24-01-SUMMARY.md, 24-02-SUMMARY.md, 24-03-SUMMARY.md]
started: 2026-03-13T23:50:00Z
updated: 2026-03-14T00:10:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Login Activity Tracking
expected: Sign in to your account. Then verify the user record has last_sign_in_at set to roughly now and sign_in_count incremented (e.g., via bin/rails runner "puts User.find_by(email_address: 'your@email.com').slice(:last_sign_in_at, :sign_in_count)" or by checking the /admin dashboard after completing test 6).
result: pass

### 2. Settings Mission Control Admin Links
expected: Navigate to Settings (as an admin user). The Mission Control card should show three sub-links: "Jobs", "Users", and "Stats". Non-admin users should not see this card at all.
result: issue
reported: "pass but why are users and stats with mission control? That for dealing with jobs and queues. shouldn't it be in it's own section?"
severity: minor

### 3. Admin Users Page — User List
expected: Navigate to /admin/users. You should see a table listing all registered users with columns: Email, Name, Joined, Last Sign In, Sign-ins, Admin status, and an action button to toggle admin. Your own row should have the action button disabled (cannot change your own admin status).
result: issue
reported: "pass, but the layout is awful"
severity: cosmetic

### 4. Admin Toggle — Grant Admin
expected: On /admin/users, click "Make admin" on a non-admin user. A browser confirm dialog should appear. Confirm it. The page reloads with a flash notice and that user's row now shows the Admin badge and a "Remove admin" button.
result: issue
reported: "the notice says remove"
severity: major

### 5. Admin Toggle — Self-demotion Block
expected: On /admin/users, the action button on your own row should be disabled (grayed out) with a tooltip "Cannot change your own admin status". Attempting to click it should do nothing.
result: issue
reported: "not grayed out and if you are creating a new view, page, etc... it should always be styled appropiately for Asthma Buddy"
severity: major

### 6. Admin Stats Dashboard
expected: Navigate to /admin (or click "Stats" in the Settings Mission Control card). You should see a page with 6 metric cards: Total Users, New This Week, New This Month, WAU (signed in last 7 days), MAU (signed in last 30 days), and Never Returned. Below, two tables: "Recent Signups" (email, name, joined) and "Most Active" (email, sign-ins, last sign-in).
result: issue
reported: "pass, but styling of all elements could be much better"
severity: cosmetic

## Summary

total: 6
passed: 1
issues: 5
pending: 0
skipped: 0

## Gaps

- truth: "Admin Users and Stats links live in a dedicated 'Admin' card, separate from Mission Control (Jobs)"
  status: failed
  reason: "User reported: pass but why are users and stats with mission control? That for dealing with jobs and queues. shouldn't it be in it's own section?"
  severity: minor
  test: 2
  artifacts: []
  missing: []

- truth: "/admin/users page layout matches the app's visual design (page header, section card, app-styled table)"
  status: failed
  reason: "User reported: pass, but the layout is awful"
  severity: cosmetic
  test: 3
  artifacts: []
  missing: []

- truth: "Flash notice after granting admin reads 'X is now an admin' (not 'no longer an admin')"
  status: failed
  reason: "User reported: the notice says remove"
  severity: major
  test: 4
  artifacts: []
  missing: []

- truth: "Own-user toggle button is visually disabled (grayed out) with disabled attribute on /admin/users"
  status: failed
  reason: "User reported: not grayed out"
  severity: major
  test: 5
  artifacts: []
  missing: []

- truth: "/admin stats dashboard elements are styled using the Asthma Buddy design system"
  status: failed
  reason: "User reported: pass, but styling of all elements could be much better"
  severity: cosmetic
  test: 6
  artifacts: []
  missing: []
