---
status: complete
phase: 15-health-events
source: [15-01-SUMMARY.md, 15-02-SUMMARY.md, 15-03-SUMMARY.md]
started: 2026-03-09T00:00:00Z
updated: 2026-03-09T12:00:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Medical History page loads
expected: Navigate to /health_events — page titled "Medical History" appears with an "Add event" button and either an empty-state or a list of events.
result: pass
note: URL is /medical-history (not /health_events as expected)

### 2. Add an illness event (duration type)
expected: |
  Click "Add event". Select "Illness" from the event type dropdown.
  A date field and a duration section appear (Still ongoing checkbox + end date).
  Fill in a start date, check "Still ongoing", and save.
  The new illness event appears in the list under the correct month heading.
result: pass
note: Initially failed with orphan action_text_rich_texts rows (fixed by migration cleanup)

### 3. Add a GP appointment (point-in-time type)
expected: |
  Click "Add event". Select "GP appointment" from the event type dropdown.
  The duration section (end date + ongoing checkbox) disappears — only a
  single date/time field is shown. Fill it in and save.
  The GP appointment appears in the list with no end date displayed.
result: pass

### 4. Edit a health event
expected: |
  Click edit on an existing event. The edit form pre-fills with current values.
  Change the event type or date and save. The list immediately reflects
  the updated values without a full page reload.
result: pass

### 5. Delete a health event
expected: |
  Click delete on an existing event. A confirmation dialog appears asking
  you to confirm the deletion. Confirm it.
  The event is removed from the list. A "Medical event deleted." toast message
  appears. If that was the last event for a month, the month heading disappears.
  If it was the last event overall, the empty state appears.
result: issue
reported: "The event count above the H1 header didn't update automatically — only updates after a full page reload"
severity: minor
fixed: "Added id=health_events_count + turbo_stream.update in destroy.turbo_stream.erb (commit f6b49e5)"

### 6. Point-in-time event shows single timestamp
expected: |
  In the Medical History list, a GP appointment or Medication change event
  displays only a single date/time — not a date range or "Ongoing" badge.
result: pass

### 7. Duration event shows date range
expected: |
  An illness or hospital visit event with both a start date and end date
  displays as a date range (e.g. "12 Feb 2026 → 18 Feb 2026") in the list.
result: pass
note: Time component not shown yet — logged as todo #161

### 8. Ongoing event shows badge
expected: |
  An illness or hospital visit event with no end date shows an "Ongoing" badge
  (rendered in uppercase via CSS). No end date is displayed for it.
result: pass

### 9. Auth guard — unauthenticated access redirected
expected: |
  Sign out, then try navigating directly to /health_events.
  You should be redirected to the sign-in page, not see the list.
result: pass

### 10. Health event markers on dashboard chart
expected: |
  With at least one health event recorded this week and at least one peak flow
  reading this week, visit the dashboard.
  The 7-day peak flow chart should show a dashed coloured vertical line at
  the date of the health event, with a short label (e.g. "Ill", "GP", "Hosp").
result: issue
reported: "Dashed vertical line is visible but the label text is unreadable"
severity: minor
fixed: "Label was drawn at top-4 (above chartArea, clipped). Moved to top+14 (commit 0c66db9)"

## Summary

total: 10
passed: 8
issues: 2
pending: 0
skipped: 0

## Gaps

[none yet]
