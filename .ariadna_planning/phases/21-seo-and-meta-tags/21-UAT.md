---
status: complete
phase: 21-seo-and-meta-tags
source: 21-01-SUMMARY.md, 21-02-SUMMARY.md, 21-03-SUMMARY.md
started: 2026-03-12T16:30:00Z
updated: 2026-03-12T16:30:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Dashboard meta description in page source
expected: Open Dashboard, view source. A `<meta name="description" content="...">` tag appears in the `<head>` after the `<title>` tag.
result: pass

### 2. Dashboard browser tab title
expected: Browser tab reads "Dashboard — Asthma Buddy" (em-dash, not hyphen).
result: pass

### 3. Authenticated page titles — Asthma Buddy suffix
expected: Navigate to Symptom Logs, Peak Flow, and Notifications. Each browser tab shows "Page Name — Asthma Buddy" (e.g. "Symptom Logs — Asthma Buddy", "Peak Flow — Asthma Buddy", "Notifications — Asthma Buddy").
result: issue
reported: "It actually says Symptoms and not Symptom Logs"
severity: minor

### 4. Medications page title corrected
expected: Go to Settings → Medications → Add Medication. Browser tab shows "Add Medication — Asthma Buddy" — NOT "Add Medication — Settings".
result: pass

### 5. Symptom Entry show page title corrected
expected: Open an existing symptom log entry (click any entry in the Symptom Logs list). Browser tab shows "Symptom Entry — Asthma Buddy" — NOT "Symptoms Log — Asthma Buddy".
result: issue
reported: "It doesn't display the content of the entry. It says content missing. The browser tab reads Symptoms - Asthma Buddy"
severity: major

### 6. Sign-in page meta description
expected: Visit the sign-in page (/sessions/new) logged out or in incognito. View source shows a `<meta name="description">` tag in the head with a description about signing in to Asthma Buddy.
result: pass

### 7. Onboarding page meta description
expected: View source of the onboarding wizard page (/onboarding). A `<meta name="description">` tag is present in the `<head>` with a description about setting up the account.
result: skipped
reason: Route is /onboarding/step/1 — not accessible to an already-onboarded user without a fresh account

## Summary

total: 7
passed: 4
issues: 2
pending: 0
skipped: 1

## Gaps

- truth: "Symptom Logs index page title reads 'Symptom Logs — Asthma Buddy'"
  status: failed
  reason: "User reported: It actually says Symptoms and not Symptom Logs"
  severity: minor
  test: 3
  artifacts: []
  missing: []

- truth: "Symptom log show page displays entry content and title reads 'Symptom Entry — Asthma Buddy'"
  status: failed
  reason: "User reported: It doesn't display the content of the entry. It says content missing. The browser tab reads Symptoms - Asthma Buddy"
  severity: major
  test: 5
  artifacts: []
  missing: []
