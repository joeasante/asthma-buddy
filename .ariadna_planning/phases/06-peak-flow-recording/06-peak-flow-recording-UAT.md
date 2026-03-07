---
status: complete
phase: 06-peak-flow-recording
source: [06-01-SUMMARY.md, 06-02-SUMMARY.md, 06-03-SUMMARY.md, 06-04-SUMMARY.md]
started: 2026-03-07T00:00:00Z
updated: 2026-03-07T00:00:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Set personal best in settings
expected: Visit /settings. You should see a "Settings" heading and a form to enter your personal best peak flow (L/min). Enter 520, submit. The page should reload showing "520 L/min" as your current personal best with a date.
result: pass

### 2. Personal best validation
expected: On /settings, try submitting a value of 50 (below the 100 minimum). An inline error should appear — no page redirect. The current personal best should remain unchanged.
result: pass

### 3. Banner when no personal best set
expected: From a fresh account with no personal best set, visit /peak-flow-readings/new. A yellow/amber banner should appear above the form warning you to set your personal best first, with a link to /settings.
result: pass

### 4. No banner when personal best is set
expected: With a personal best already set (e.g. 520 L/min), visit /peak-flow-readings/new. The yellow banner should NOT appear — just the entry form.
result: pass

### 5. Record a peak flow reading — Green zone
expected: With a personal best of 520 L/min set, enter a value of 442 (85% of 520 → Green Zone) and submit. A flash message should appear saying "Reading saved — Green Zone (85% of personal best)." — without a full page reload. The form should reset.
result: pass

### 6. Zone flash with no personal best
expected: Delete your personal best (or test from an account with none set), then record any reading (e.g. 400). The flash should say something like "Reading saved — set your personal best to see your zone." No zone colour shown.
result: issue
reported: "Pass, but it didn't show the actual colour when there was a personal best set. It just mentioned the name of the colour (Yellow)"
severity: minor

### 7. Peak flow reading validation
expected: On /peak-flow-readings/new, clear the value field and submit. An inline validation error should appear — the form stays put, no redirect. Try submitting 950 (above max 900) — also shows an error.
result: issue
reported: "If I try submitting nothing, there is no warning. Over 900, then there is a warning"
severity: major

### 8. Form resets after successful recording
expected: Submit a valid reading. The value field should clear back to empty and the datetime should reset to current time — ready for another entry — without a full page reload.
result: issue
reported: "No, the form didn't clear and the previous message about reading saved remained and another appeared below it"
severity: major

## Summary

total: 8
passed: 5
issues: 3
pending: 0
skipped: 0

## Gaps

- truth: "Submitting a blank value on the peak flow entry form shows an inline validation error"
  status: failed
  reason: "User reported: If I try submitting nothing, there is no warning. Over 900, then there is a warning"
  severity: major
  test: 7
  artifacts: []
  missing: []

- truth: "Zone flash message shows the zone colour visually (green/yellow/red) alongside the zone name when a reading is saved with a personal best set"
  status: failed
  reason: "User reported: Pass, but it didn't show the actual colour when there was a personal best set. It just mentioned the name of the colour (Yellow)"
  severity: minor
  test: 6
  artifacts: []
  missing: []

- truth: "After a successful recording the form resets (value clears, datetime resets) and old flash messages are replaced not accumulated"
  status: failed
  reason: "User reported: No, the form didn't clear and the previous message about reading saved remained and another appeared below it"
  severity: major
  test: 8
  artifacts: []
  missing: []
