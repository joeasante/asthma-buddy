---
status: pending
priority: p2
issue_id: "169"
tags: [code-review, stimulus, javascript, forms]
dependencies: []
---

# tod_sync_controller Sets .checked Programmatically Without Dispatching change Event

## Problem Statement
`tod_sync_controller.js` sets `this.morningTarget.checked = isMorning` and `this.eveningTarget.checked = !isMorning` by direct property assignment. Direct property assignment to `.checked` does NOT fire a native `change` event on the radio inputs. If any other Stimulus controller or event listener watches for `change` on those radio buttons (e.g., a future zone_preview extension, or analytics), it will silently not react when tod-sync programmatically changes the selection. This is a correctness issue that is invisible today but will silently break any future listener attached to those inputs.

## Findings
- `tod_sync_controller.js` modifies radio input state via direct `.checked` property assignment
- The native `change` event is only fired when a user physically interacts with an input — not when `.checked` is set programmatically
- No current listener relies on this event, so the bug is latent but real
- The fix is a one-liner per toggled radio

## Proposed Solutions

### Option A
After setting `.checked` on the radio that was just activated, dispatch a synthetic change event on it: `this.morningTarget.dispatchEvent(new Event("change", { bubbles: true }))` (or `this.eveningTarget`, whichever was just checked). Using `bubbles: true` ensures any delegated listener on a parent element also receives the event.
- Pros: Restores expected DOM event semantics; one-liner fix; no behaviour change for current code; future-proofs the controller
- Cons: None
- Effort: Small
- Risk: Low

## Recommended Action

## Technical Details
- Affected files:
  - `app/javascript/controllers/tod_sync_controller.js`

## Acceptance Criteria
- [ ] After programmatically setting a radio input's `.checked` state, a synthetic `change` event with `bubbles: true` is dispatched on the newly-checked input
- [ ] Existing tod-sync behaviour (time-of-day selection syncing) continues to work as before
- [ ] A test or comment documents the reason for the explicit dispatch

## Work Log
- 2026-03-10: Created via code review
