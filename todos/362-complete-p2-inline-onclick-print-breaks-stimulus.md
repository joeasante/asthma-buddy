---
status: complete
priority: p2
issue_id: 362
tags: [code-review, frontend, stimulus]
dependencies: []
---

## Problem Statement

Two `onclick="window.print()"` handlers in the appointment summary view break the Stimulus conventions used throughout the rest of the codebase.

## Findings

In `app/views/appointment_summaries/show.html.erb`, there are two inline `onclick="window.print()"` event handlers. The entire codebase uses Stimulus controllers for interactive behavior, making these inline handlers inconsistent with established conventions. Inline handlers also bypass CSP `script-src` restrictions if nonce-based CSP is enforced.

## Proposed Solutions

**A) Create a small `print_controller.js` Stimulus controller**
- Pros: Consistent with codebase conventions; CSP-safe; reusable if print is needed elsewhere
- Cons: New file for a trivial action

**B) Use `data-action="click->print#print"` with a generic controller**
- Pros: Same as A but emphasizes the Stimulus data-action pattern
- Cons: Essentially the same as A

## Recommended Action



## Technical Details

**Affected files:**
- `app/views/appointment_summaries/show.html.erb`

## Acceptance Criteria

- [ ] No inline onclick handlers in the view
- [ ] Print functionality uses Stimulus controller
