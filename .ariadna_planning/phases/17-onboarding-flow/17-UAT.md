---
status: complete
phase: 17-onboarding-flow
source: [17-01-SUMMARY.md, 17-02-SUMMARY.md]
started: 2026-03-10T18:00:00Z
updated: 2026-03-10T18:30:00Z
---

## Current Test

[testing complete]

## Tests

### 1. New user redirected to onboarding
expected: Sign up as a brand new user (no personal best, no medications). After email verification and login, visiting /dashboard redirects you to the onboarding wizard (Step 1: set personal best). You should NOT see the dashboard — you land on the onboarding step 1 page.
result: pass

### 2. Progress indicator shows 2 steps
expected: On the onboarding page (step 1 or step 2), the progress indicator shows "Step X of 2" — two dots/steps visible. There is no step 3 indicator.
result: pass

### 3. Complete Step 1 (set personal best)
expected: On step 1, enter a valid personal best value (e.g. 550) and submit. You advance to Step 2 (Add your inhaler). The personal best is saved.
result: pass

### 4. Skip Step 1
expected: On step 1, click "Skip this step". You advance to Step 2 (Add your inhaler) without entering a personal best.
result: skipped

### 5. Complete Step 2 (add medication)
expected: On step 2, fill in a medication name (e.g. "Ventolin"), select type "reliever", enter puffs per dose (e.g. 2), and submit. You are redirected to the dashboard with a welcome message ("Welcome to Asthma Buddy!").
result: pass

### 6. Skip Step 2
expected: On step 2, click "Skip this step". You are redirected to the dashboard with a notice ("You can complete setup any time from Settings.").
result: issue
reported: "No notice appeared"
severity: minor

### 7. Skip both steps
expected: On step 1, click skip. On step 2, click skip. You reach the dashboard. On subsequent logins, the wizard does NOT reappear — you go straight to the dashboard.
result: pass

### 8. Returning user bypasses wizard
expected: Log in as a user who already has a personal best and at least one medication. Visiting / or /dashboard takes you straight to the dashboard — no onboarding wizard shown.
result: pass

## Summary

total: 8
passed: 6
issues: 1
pending: 0
skipped: 1

## Gaps

- truth: "Skipping step 2 redirects to dashboard with notice 'You can complete setup any time from Settings.'"
  status: failed
  reason: "User reported: No notice appeared"
  severity: minor
  test: 6
  artifacts: []
  missing: []
