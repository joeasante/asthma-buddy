---
status: complete
phase: 18-temporary-medication-courses
source: 18-01-SUMMARY.md, 18-02-SUMMARY.md, 18-03-SUMMARY.md
started: 2026-03-10T00:00:00Z
updated: 2026-03-10T00:00:00Z
---


## Tests

### 1. Add a course medication via the form
expected: Open the medication form (Settings → Medications → Add medication). Check the "Course" checkbox — the start date and end date fields appear, and the "Doses per day" field hides. Fill in name, type, start date, end date (at least 2 days apart). Submit. The medication appears in the main list with a "Course" badge and the end date shown.
result: pass

### 2. Course toggle restores state on validation error
expected: Open the Add medication form, check "Course", fill only the name (leave start/end dates blank), submit. The form re-renders with validation errors — the "Course" checkbox should still be checked and the date fields still visible (not collapsed back to hidden).
result: pass

### 3. Active course has Log dose button
expected: In the medications list, the active course medication you just added has a "Log dose" button/panel just like a regular medication.
result: pass

### 4. Active course excluded from low-stock alerts
expected: Go to the Dashboard. The active course medication does NOT appear in the Low Stock section (if that section is visible), even if it has a low remaining supply.
result: pass

### 5. Active course excluded from Today's Doses
expected: Go to the Dashboard (Home tab). The Prednisolone course should NOT appear in the "Today's Doses" section.
result: pass

### 6. Past courses section hidden when none exist
expected: If you have no expired/archived courses, the "Past courses" section does not appear on the medications page at all.
result: pass

### 7. Past courses section appears when a course expires
expected: Add a new course medication with start date 01/03/2026 and end date 08/03/2026 (both in the past). After saving, go to the Medications page. A collapsed "Past courses (1)" section should appear.
result: pass

### 8. Archived course rows are read-only
expected: In the Past courses section, archived course rows have no "Log dose" button. The overflow menu only shows "Remove" (no "Edit").
result: pass

### 9. Edit a course medication
expected: Open an active course medication's overflow menu and click "Edit". The form opens with the Course checkbox checked and date fields pre-filled. Make a change (e.g. extend end date by a day) and save. The card updates in place without a full page reload.
result: pass

### 10. Remove a course medication
expected: Open an active course medication's overflow menu and click "Remove". The medication disappears from the list immediately (Turbo Stream removes it in place).
result: pass

## Summary

total: 10
passed: 10
issues: 0
pending: 0
skipped: 0

## Gaps

<!-- Filled as issues are found during testing -->
