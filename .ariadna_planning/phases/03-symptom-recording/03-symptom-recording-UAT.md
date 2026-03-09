---
status: diagnosed
phase: 03-symptom-recording
source: 03-01-SUMMARY.md, 03-02-SUMMARY.md, 03-03-SUMMARY.md
started: 2026-03-07T09:45:00Z
updated: 2026-03-07T10:10:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Log a Symptom
expected: Visit /symptom_logs while signed in. Form has Symptom Type, Severity, datetime, and notes fields. Fill in type + severity and submit — entry appears at top of list instantly (no page reload, Turbo Stream).
result: pass

### 2. Form Clears After Submission
expected: After submitting a valid entry, the form immediately resets to a blank state (empty selects, datetime reset to now, notes cleared) — ready to log another symptom without any manual clearing.
result: pass

### 3. Notes Field Works
expected: Type text in the notes editor (the rich-text area). Submit the entry. The notes text should appear in the entry that was just added to the list.
result: pass

### 4. Validation Errors Appear Inline
expected: Submit the form without selecting a Symptom Type or Severity. The page should NOT navigate away. Error messages should appear inside the form (e.g. "Symptom type can't be blank") with no full-page reload.
result: issue
reported: "It told me to select an item in the list for symptom type"
severity: minor

### 5. Multi-User Isolation
expected: Sign in as one user and log a symptom entry. Sign out, sign in as a different user, and visit /symptom_logs. The first user's entries should NOT appear in the second user's list.
result: pass

### 6. Unauthenticated Redirect
expected: Visit /symptom_logs while signed out. You should be redirected to the sign-in page rather than seeing the symptom log form or any entries.
result: pass

## Summary

total: 6
passed: 5
issues: 1
pending: 0
skipped: 0

## Gaps

- truth: "Submitting an empty form shows Rails inline validation errors without leaving the page"
  status: failed
  reason: "User reported: It told me to select an item in the list for symptom type"
  severity: minor
  test: 4
  root_cause: "HTML required: true attribute on symptom_type and severity selects causes browser native validation to intercept the submit before Rails sees it, preventing the Turbo Stream 422 error path from firing"
  artifacts:
    - path: "app/views/symptom_logs/_form.html.erb"
      issue: "{ required: true } HTML option on both select fields and datetime_local_field"
  missing:
    - "Remove required: true HTML attributes from selects (and datetime field) — Rails model validations already enforce presence; browser validation blocks the Turbo Stream error path"
  debug_session: ""
