---
status: complete
priority: p3
issue_id: "284"
tags: [code-review, javascript, stimulus, yagni, frontend]
dependencies: []
---

# `safetyInterval` in `day_reset_controller.js` is YAGNI

## Problem Statement

`day_reset_controller.js` sets a `safetyInterval` (a `setInterval` that polls periodically) as a belt-and-suspenders fallback in case `visibilitychange` events are missed. Modern browsers (Chrome 65+, Safari 14.1+, Firefox 68+) fire `visibilitychange` reliably when the tab is backgrounded and foregrounded. The interval adds complexity, an extra timer reference to manage, and a `disconnect()` teardown obligation — all for a failure mode that does not exist in any supported browser.

## Findings

- **File:** `app/javascript/controllers/day_reset_controller.js` — `safetyInterval` setup and teardown
- **Agent:** code-simplicity-reviewer, julik-frontend-races-reviewer

## Proposed Solutions

### Option A — Remove `safetyInterval`, rely on `visibilitychange` only (Recommended)

```js
// Remove: this.safetyInterval = setInterval(...)
// Remove: clearInterval(this.safetyInterval) in disconnect()
// Keep: document.addEventListener("visibilitychange", this.checkForDayChange)
```

**Pros:** Simpler. No timer to manage. No drift risk from interval + event double-firing.
**Effort:** Trivial
**Risk:** None for supported browsers

### Option B — Keep as-is with a comment

Add `// belt-and-suspenders for legacy browsers` and accept the extra code.

**Pros:** Maximally defensive.
**Cons:** Code for a hypothetical that will never occur in this app's browser matrix.
**Effort:** Trivial
**Risk:** None

## Recommended Action

Option A.

## Technical Details

- **Affected file:** `app/javascript/controllers/day_reset_controller.js`

## Acceptance Criteria

- [ ] `safetyInterval` and its `clearInterval` teardown are removed
- [ ] Day-reset behaviour on tab focus is unchanged (covered by `visibilitychange`)

## Work Log

- 2026-03-11: Identified by code-simplicity-reviewer during code review of dev branch
