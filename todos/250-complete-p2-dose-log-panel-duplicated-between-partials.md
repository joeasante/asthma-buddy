---
status: pending
priority: p2
issue_id: "250"
tags: [code-review, duplication, rails, views]
dependencies: []
---

# Dose-Log Panel Block Duplicated Verbatim Between `_medication` and `_course_medication`

## Problem Statement

The 24-line log dose panel (`<details class="med-log-details">` block with the dose log form + last-7-days history) is copy-pasted identically between `_medication.html.erb` and `_course_medication.html.erb`. Any change to the log panel (e.g., adding a "last dose taken" timestamp, changing the history limit, updating ARIA labels) requires editing two files. There is already a comment in `_course_medication.html.erb` acknowledging this: "identical to regular medication".

## Findings

`app/views/settings/medications/_medication.html.erb` lines 22–45: full dose-log panel block
`app/views/settings/medications/_course_medication.html.erb` lines 25–48: character-for-character identical block

Both contain:
- `<details class="med-log-details">` with Stimulus targets
- `settings/dose_logs/form` render call
- `dose_history_` section with 7-day limit and empty state

Confirmed by: pattern-recognition-specialist, code-simplicity-reviewer.

## Proposed Solutions

### Option A — Extract `_dose_log_panel` shared partial *(Recommended)*

Create `app/views/settings/medications/_dose_log_panel.html.erb` containing the shared block, then both partials call:

```erb
<%= render "settings/medications/dose_log_panel", medication: medication %>
```

Pros: single source of truth, correct Rails pattern for shared sub-partials
Cons: one new file

### Option B — Leave as-is with a comment

Add a maintenance comment pointing to the other file.

Pros: zero code change
Cons: divergence still happens; already self-documented and the duplication still exists

## Recommended Action

Option A — extract the partial. This is the Rails-idiomatic solution.

## Technical Details

- **Files to modify:**
  - `app/views/settings/medications/_medication.html.erb` (replace 24 lines with one render call)
  - `app/views/settings/medications/_course_medication.html.erb` (replace 24 lines with one render call)
- **New file:** `app/views/settings/medications/_dose_log_panel.html.erb`

## Acceptance Criteria

- [ ] `_dose_log_panel.html.erb` partial created with the shared block
- [ ] Both `_medication` and `_course_medication` render the shared partial
- [ ] No visual change to either UI
- [ ] Existing system tests for dose logging continue to pass

## Work Log

- 2026-03-10: Found by pattern-recognition-specialist and code-simplicity-reviewer during Phase 18 code review
