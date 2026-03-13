---
status: complete
phase: 23-compliance-security-accessibility
source: [23-01-SUMMARY.md]
started: 2026-03-13T21:30:00Z
updated: 2026-03-13T22:00:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Normal Login Still Works
expected: Navigate to /session/new (login page). Enter valid credentials and submit. You should be redirected to the dashboard. No errors, no unexpected redirects.
result: pass

### 2. Signup Page Still Works
expected: Navigate to /registration/new (signup page). The form loads without error. Fill in a new email/password and submit — you should be taken through the email verification flow normally. (You don't need to complete full signup — just confirm the form submits without a 429 or error.)
result: pass

### 3. Rate Limiting on Login (429 After Rapid Attempts)
expected: On the login page, submit the form with incorrect credentials 6 times in quick succession (within ~20 seconds). The 6th attempt should return a "Too Many Requests" response (HTTP 429 page or plain-text message). Earlier attempts show the normal "Invalid email or password" error.
result: issue
reported: "It said try again later. Need a better error message though"
severity: minor

### 4. Active Session Stays Alive
expected: Log in and use the app normally — navigate between pages (dashboard, peak flow, symptoms). Your session should remain active. No "session expired" redirect appears during normal active use. (This confirms last_seen_at refreshes on each request, preventing premature timeout.)
result: pass

### 5. Session Expired Redirect (Simulated)
expected: This test is hard to verify manually without waiting 60 minutes. You can skip if you'd prefer, or: log in, then use browser devtools to manually clear/edit the session cookie so last_seen_at appears old — then navigate to a protected page. The app should redirect you to login with an alert "Your session expired due to inactivity." (Skip if this is too involved.)
result: skipped

## Summary

total: 5
passed: 3
issues: 1
pending: 0
skipped: 1

## Gaps

- truth: "Rate limit response includes a clear, specific error message explaining what happened and when to retry"
  status: failed
  reason: "User reported: It said try again later. Need a better error message though"
  severity: minor
  test: 3
  artifacts: []
  missing: []
