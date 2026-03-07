---
status: diagnosed
phase: 05-symptom-timeline
source: 05-01-SUMMARY.md, 05-02-SUMMARY.md
started: 2026-03-07T14:00:00Z
updated: 2026-03-07T14:30:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Timeline view — chronological list
expected: Navigate to the symptom logs page (sign in first if needed). Your entries should appear in reverse-chronological order — newest first. Each row shows the symptom type, severity, and timestamp at a glance.
result: pass

### 2. Severity trend bar
expected: Above the list, a horizontal stacked bar shows the proportion of mild / moderate / severe entries across your history (e.g., 40% mild, 40% moderate, 20% severe in distinct colours). The bar is visible as long as there is at least one entry.
result: issue
reported: "Yes, but when I added an entry for severe it didn't appear in the bar immediately I had to refresh the page"
severity: major

### 3. Preset date filter chips
expected: Clicking "7d", "30d", or "90d" chips filters the list to that window — only entries within the last 7/30/90 days appear. The page heading stays visible (no full page reload), confirming the Turbo Frame updated only the content area. Clicking "All" restores the full history.
result: issue
reported: "the 30d button doesn't appear to work"
severity: major

### 4. Custom date range filter
expected: Entering a start date and end date in the date inputs and submitting shows only entries within that range. Entries outside the range disappear from the list.
result: pass

### 5. Pagination
expected: If you have more than 25 entries, Prev/Next buttons appear at the bottom. Clicking Next shows the next page of older entries; Prev returns to the previous page. A page indicator (e.g., "Page 2 of 4") is visible.
result: skipped
reason: not enough entries to test

### 6. New entry prepends to list
expected: Submit a new symptom log via the form at the top. The new entry appears at the top of the timeline immediately — without a full page reload.
result: issue
reported: "Tried to log a symptom for 07/03/2026 at 09:30:00, but got an error stating: please enter a valid value. The two nearest valid values are 07/03/2026, 09:29:39 and 07/03/2026, 09:30:39"
severity: major

### 7. Inline edit from timeline row
expected: Click the Edit button on any timeline row. An inline edit form replaces the row in place. Change a field (e.g., severity), save — the updated row appears immediately without a page reload.
result: pass

### 8. Delete from timeline row
expected: Click the Delete button on any timeline row. The entry is removed from the list immediately without a page reload.
result: pass

## Summary

total: 8
passed: 4
issues: 4
pending: 0
skipped: 1

## Gaps

- truth: "The severity trend bar updates immediately when a new entry is submitted, without requiring a page refresh"
  status: failed
  reason: "User reported: when I added an entry for severe it didn't appear in the bar immediately I had to refresh the page"
  severity: major
  test: 2
  root_cause: "create.turbo_stream.erb only prepends the new row — it never recomputes @severity_counts nor emits a Turbo Stream replace for the trend bar, so the bar's DOM stays frozen at its pre-submission state"
  artifacts:
    - path: "app/controllers/symptom_logs_controller.rb"
      issue: "create action never computes @severity_counts — that assignment lives only in index"
    - path: "app/views/symptom_logs/create.turbo_stream.erb"
      issue: "no turbo_stream.replace operation for the trend bar"
    - path: "app/views/symptom_logs/index.html.erb"
      issue: "trend bar has no stable DOM id for turbo_stream.replace to target"
  missing:
    - "Add id='trend_bar' wrapper around the _trend_bar render in index.html.erb"
    - "Compute @severity_counts in the create action after successful save"
    - "Add turbo_stream.replace 'trend_bar' to create.turbo_stream.erb"
  debug_session: ""

- truth: "Clicking the 30d chip filters the timeline to entries from the last 30 days and the chip appears visually active"
  status: failed
  reason: "User reported: the 30d button doesn't appear to work"
  severity: major
  test: 3
  root_cause: "The filter bar is rendered outside turbo_frame_tag 'timeline_content', so frame responses never re-render the bar — the active-chip CSS class never updates, giving no visual confirmation the filter applied, making it appear broken even though the list does filter"
  artifacts:
    - path: "app/views/symptom_logs/index.html.erb"
      issue: "filter_bar is rendered outside the timeline_content Turbo Frame — frame responses do not re-render it, so active chip state is never reflected"
    - path: "app/views/symptom_logs/_filter_bar.html.erb"
      issue: "chip links target the frame but the bar itself is never updated by frame responses"
  missing:
    - "Move the filter_bar render inside turbo_frame_tag 'timeline_content' so the active chip state and list update together on each frame request"
  debug_session: ""

- truth: "The recorded_at datetime input does not show seconds and accepts clean minute-boundary values without browser validation errors"
  status: failed
  reason: "User reported: seconds are shown in the input, and entering 09:30:00 triggers a browser error — nearest valid values shown as 09:29:39 and 09:30:39"
  severity: major
  test: 6
  root_cause: "The controller initialises recorded_at with raw Time.current (including seconds e.g. 09:15:39) and the form renders datetime_local_field with no step attribute, so the browser's default step=60 aligns valid values to :39-second marks, rejecting clean minute-boundary entries"
  artifacts:
    - path: "app/controllers/symptom_logs_controller.rb"
      issue: "recorded_at default is Time.current — includes seconds, misaligning the step-60 anchor"
    - path: "app/views/symptom_logs/_form.html.erb"
      issue: "datetime_local_field :recorded_at has no step: 60 attribute"
  missing:
    - "Change Time.current to Time.current.change(sec: 0) in the controller to align the anchor to a whole minute"
    - "Add step: 60 to the datetime_local_field in _form.html.erb"
  debug_session: ""
