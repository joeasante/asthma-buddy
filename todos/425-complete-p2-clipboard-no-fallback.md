---
status: pending
priority: p2
issue_id: 425
tags: [code-review, frontend, stimulus, accessibility]
dependencies: []
---

# Clipboard controller has no error fallback

## Problem Statement

The Stimulus `clipboard_controller.js` uses `navigator.clipboard.writeText()` with a `.then()` success handler but no `.catch()`. If the Clipboard API fails (non-HTTPS, older browsers, some WebViews, permission denied), the button does nothing with no user feedback.

## Findings

- **Source**: kieran-rails-reviewer (Finding #14)
- **Location**: `app/javascript/controllers/clipboard_controller.js:10`

## Proposed Solutions

### Option A: Add .catch() with fallback
- **Approach**: Add a `.catch()` that shows "Failed to copy" feedback, optionally falling back to `document.execCommand("copy")`
- **Effort**: Small
- **Risk**: Low

## Acceptance Criteria

- [ ] Failed clipboard write shows user feedback
- [ ] Button does not silently fail

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-14 | Created from code review | |

## Resources

- PR #24: https://github.com/joeasante/asthma-buddy/pull/24
