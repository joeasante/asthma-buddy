---
status: pending
priority: p2
issue_id: "223"
tags: [frontend, accessibility, stimulus, code-review]
dependencies: []
---

# Cookie Notice Dismiss Button Stuck Visible When CSS Transitions Are Disabled

## Problem Statement

`cookie_notice_controller.js` relies on the `transitionend` DOM event to remove the banner from the DOM after the user clicks dismiss. If the user has `prefers-reduced-motion: reduce` set (an OS-level accessibility setting), or if the CSS transition is suppressed for any other reason, the event never fires and the element is never removed from the DOM.

The session flag is correctly set server-side, so the banner will not reappear on the next page load. However, on the current page visit the banner stays visible as a stuck, non-interactive element after the user clicks dismiss — a broken experience for users who rely on reduced-motion settings.

## Findings

**Flagged by:** kieran-rails-reviewer

**Location:**
- `app/javascript/controllers/cookie_notice_controller.js` lines 7–9

**Current code (approximate):**
```javascript
el.addEventListener("transitionend", () => {
  this.element.remove()
}, { once: true })
```

No fallback exists if `transitionend` never fires. On browsers/systems where `prefers-reduced-motion: reduce` causes the transition duration to be `0ms` or suppressed entirely by the browser, the event is not dispatched.

## Proposed Solutions

### Option A — Add a fallback setTimeout (Recommended)

Add a `setTimeout` fallback that fires at the transition duration + buffer. Clear it if `transitionend` fires first:

```javascript
const el = this.element
const fallback = setTimeout(() => el.remove(), 400)
el.addEventListener("transitionend", () => {
  clearTimeout(fallback)
  el.remove()
}, { once: true })
```

**Pros:** Works for all users regardless of motion preference. Animated dismiss still plays normally for users without reduced-motion. Minimal code change.
**Cons:** The `400ms` constant must match or slightly exceed the CSS transition duration. If the transition duration changes in CSS, the constant needs updating (low coupling risk in practice).
**Effort:** Very small
**Risk:** None

### Option B — Detect prefers-reduced-motion and skip transition

Check the media query in the controller and remove the element immediately if reduced motion is preferred:

```javascript
if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
  this.element.remove()
  return
}
// otherwise: apply fade class + transitionend listener
```

**Pros:** Respects reduced-motion intent explicitly — no fake animation duration waited on.
**Cons:** Requires separate code paths. Does not handle the case where transitions are suppressed for reasons other than `prefers-reduced-motion` (e.g., `transition: none` in a test environment or user stylesheet).
**Effort:** Small
**Risk:** Low

## Recommended Action

Option A — add a `setTimeout` fallback. It handles all suppression cases (not just `prefers-reduced-motion`) with a single code path and minimal change. The 400ms fallback is imperceptible to the user in the normal animated case.

## Technical Details

**Affected files:**
- `app/javascript/controllers/cookie_notice_controller.js`

**Acceptance Criteria:**
- [ ] Cookie notice is removed from DOM after clicking dismiss, even with transitions disabled
- [ ] Fallback fires within 400ms if `transitionend` never fires
- [ ] Animated dismiss still works normally for users without reduced-motion preference

## Work Log

- 2026-03-10: Identified by kieran-rails-reviewer in Phase 16 code review.

## Resources

- MDN `transitionend`: https://developer.mozilla.org/en-US/docs/Web/API/Element/transitionend_event
- MDN `prefers-reduced-motion`: https://developer.mozilla.org/en-US/docs/Web/CSS/@media/prefers-reduced-motion
- WCAG 2.1 SC 2.3.3 (Animation from Interactions)
