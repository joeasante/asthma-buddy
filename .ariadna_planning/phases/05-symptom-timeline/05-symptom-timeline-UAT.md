---
status: complete
phase: 05-symptom-timeline
source: 05-01-SUMMARY.md, 05-02-SUMMARY.md, 05-03-SUMMARY.md
started: 2026-03-07T16:00:00Z
updated: 2026-03-07T16:00:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Timeline view — reverse-chronological list
expected: Navigate to the symptom logs page (sign in if needed). Your entries should appear newest first. Each row shows the symptom type, severity, and timestamp at a glance.
result: pass

### 2. Severity trend bar displays
expected: Above the list, a horizontal stacked bar shows the proportion of mild / moderate / severe entries across your full history in distinct colours. The bar is visible as long as there is at least one entry.
result: pass

### 3. Trend bar live-updates after new entry
expected: Submit a new symptom entry using the form. The severity trend bar should update immediately — without a page refresh — to reflect the new entry's severity in the distribution.
result: pass

### 4. New entry prepends without page reload
expected: After submitting the new entry, it appears at the top of the timeline list immediately. The page heading stays visible (confirming no full page reload occurred).
result: pass

### 5. Preset chip filters the list
expected: Click the "7d" chip. The timeline list updates to show only entries from the last 7 days. Entries older than 7 days disappear. The page heading remains visible (Turbo Frame update, not full reload).
result: pass

### 6. Active chip state updates
expected: After clicking "7d", that chip should appear visually distinct from the others — highlighted or otherwise marked as the active/selected filter. Clicking "All" should deactivate it and restore the highlight to the "All" chip.
result: pass

### 7. Datetime input accepts clean minute values
expected: Open the new entry form. The datetime field should default to a whole-minute time (e.g., 09:30, not 09:30:27). Changing the time to any clean hour:minute (no seconds) and submitting should not trigger a browser validation error.
result: pass

### 8. Custom date range filter
expected: Enter a start date and end date in the date inputs and submit. Only entries within that range appear. Entries outside the range disappear from the list.
result: pass

### 9. Inline edit from timeline row
expected: Click the Edit button on any timeline row. An inline edit form replaces the row. Change a field (e.g., severity), save — the updated row appears immediately without a page reload.
result: pass

### 10. Delete from timeline row
expected: Click the Delete button on any timeline row. The entry is removed from the list immediately without a page reload.
result: issue
reported: "That passed, but the browser's native confirm dialog is visually jarring and doesn't fit the look of the system — particularly as the UI is polished up"
severity: cosmetic

### 11. Pagination
expected: If you have more than 25 entries, Prev/Next buttons appear at the bottom. Clicking Next shows older entries; Prev returns to the previous page. A page indicator (e.g., "Page 2 of 4") is visible.
result: skipped
reason: not enough entries to test

## Summary

total: 11
passed: 9
issues: 1
pending: 0
skipped: 1
skipped: 0

## Gaps

- truth: "Delete confirmation uses an in-app dialog consistent with the application's visual design"
  status: failed
  reason: "User reported: the browser's native confirm dialog is visually jarring and doesn't fit the look of the system — particularly as the UI is polished up"
  severity: cosmetic
  test: 10
  artifacts: []
  missing: []
