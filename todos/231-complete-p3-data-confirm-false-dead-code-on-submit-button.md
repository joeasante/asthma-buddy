---
status: pending
priority: p3
issue_id: "231"
tags: [code-review, rails, simplification]
dependencies: []
---

# `data: { confirm: false }` on account deletion submit button is dead code

## Problem Statement

`settings/show.html.erb` line 62 has `data: { confirm: false }` on the submit button, intended to prevent a Turbo confirmation dialog from firing. But the form already has `data: { turbo: false }`, which disables Turbo entirely for this form. When Turbo is not handling the form, no `data-confirm` attribute is ever evaluated — the attribute is never read. This renders `data-confirm="false"` in the HTML for no purpose.

## Findings

**Flagged by:** phase-16-code-reviewer

**Location:** `app/views/settings/show.html.erb` (line 62)

## Proposed Solutions

### Option A (Recommended) — Remove the dead attribute

Remove `data: { confirm: false }` from the submit button. One line, zero behaviour change.

```erb
<%# Before %>
<%= f.submit "Delete my account", data: { confirm: false }, class: "btn btn--danger" %>

<%# After %>
<%= f.submit "Delete my account", class: "btn btn--danger" %>
```

**Effort:** Trivial
**Risk:** None — the form's `data: { turbo: false }` already prevents Turbo from processing this form, so no confirmation dialog can fire regardless.

## Recommended Action

Remove `data: { confirm: false }`.

## Technical Details

**Acceptance Criteria:**
- [ ] `data: { confirm: false }` removed from the submit button
- [ ] Form still submits correctly without Turbo dialog

## Work Log

- 2026-03-10: Identified by phase-16-code-reviewer.
