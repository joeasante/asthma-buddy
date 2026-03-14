---
status: testing
phase: 25-clinical-intelligence
source: [25-07-SUMMARY.md, 25-08-SUMMARY.md]
started: 2026-03-14T13:30:00Z
updated: 2026-03-14T13:45:00Z
---

## Current Test

number: 3
name: Dose log shows medication type
expected: |
  In the Dose Log section, the "Type" column shows "Reliever", "Preventer", "Combination", etc. — NOT the actual medication name (e.g. not "Ventolin").
awaiting: user response

## Tests

### 1. Mobile card layout — notes underneath
expected: On /health-report at mobile width (<768px), detail tables render as stacked cards. Each field has a label. Notes appear underneath with a dashed separator, not as a side column.
result: pass
note: "Notes underneath works. Mobile layout issues (labels spread apart, whitespace, footer, print placement) fixed in follow-up commit."

### 2. Desktop row separation
expected: On /health-report at desktop width, detail tables have alternating row backgrounds for clear visual separation between records.
result: pass

### 3. Dose log shows medication type
expected: In the Dose Log section, the "Type" column shows "Reliever", "Preventer", "Combination", etc. — NOT the actual medication name (e.g. not "Ventolin").
result: [pending]

### 4. Stats grid mobile sizing
expected: On mobile, the stats numbers (readings count, averages, etc.) are appropriately sized — not oversized or cramped.
result: [pending]

### 5. Print button — icon style
expected: The print button in the Health Report header is a small icon-style button (not an oversized btn-secondary). On desktop shows icon + "Print" text. On mobile shows as full-width button at bottom of report.
result: [pending]

### 6. Mobile Health Report access
expected: On /dashboard at mobile width, there is a visible "Health Report" button in the quick-log area that navigates to /health-report.
result: [pending]

### 7. Dose unit dropdown on medication form
expected: When adding or editing a medication in Settings, there is a "Dose unit" dropdown with options: Puffs, Tablets, Ml. Default is Puffs.
result: [pending]

### 8. Course medication — dose fields
expected: When the "temporary course" checkbox is checked on the medication form, the course section includes "Dose per session" and "Sessions per day" fields in addition to the date fields.
result: [pending]

### 9. Health Report — dynamic units
expected: On /health-report, active medications and courses show the correct unit based on their dose_unit setting. A course with dose_unit "tablets" shows "6 tablets" not "6 puffs". Courses also show frequency if set (e.g. "6 tablets x1/day").
result: [pending]

### 10. Medication card — generic refill language
expected: On the medication card in Settings, the refill form uses generic language like "Total count" — not inhaler-specific language like "puff count".
result: [pending]

## Summary

total: 10
passed: 2
issues: 0
pending: 8
skipped: 0

## Gaps

- truth: "Mobile card layout fields are easy to read with labels and values next to each other"
  status: fixed
  reason: "Fixed in follow-up commit — labels now inline with values, tighter spacing, bottom print button, actual time for peak flow"
  severity: major
  test: 1

- truth: "Peak flow readings show actual recorded time"
  status: fixed
  reason: "Changed from time_of_day label to recorded_at.strftime('%H:%M')"
  severity: minor
  test: 1
