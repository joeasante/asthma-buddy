---
status: pending
priority: p3
issue_id: 314
tags: [code-review, css, dead-code, errors]
---

# 314 — P3 — Dead animation media query block in errors.css

## Problem Statement

`app/assets/stylesheets/errors.css` lines 49–53 contain a dead `@media (prefers-reduced-motion: no-preference)` block that applies `animation: none` to `.error-code`. No animation is ever defined on `.error-code` anywhere in the stylesheet, so `animation: none` is a complete no-op. Additionally, the media query condition is semantically backwards: `prefers-reduced-motion: no-preference` targets users who have expressed no preference about motion (i.e. they accept animations), yet the block is setting `animation: none` — which is the opposite of the correct usage. The correct pattern is to define the animation unconditionally and suppress it with `animation: none` inside a `prefers-reduced-motion: reduce` query, or to apply the animation only inside `no-preference`. As written the block does nothing and misleads future maintainers.

## Findings

- `app/assets/stylesheets/errors.css` lines 49–53:

```css
@media (prefers-reduced-motion: no-preference) {
  .error-code {
    animation: none;
  }
}
```

- `.error-code` has no `animation` property defined anywhere in `errors.css` or in any other stylesheet — there is no keyframe animation associated with this class
- `animation: none` on an element that has no animation is a no-op; the browser evaluates it and discards it
- The `prefers-reduced-motion: no-preference` condition targets users who have NOT requested reduced motion — i.e. users who are comfortable with animation. Applying `animation: none` inside this query is the reverse of the accessible pattern
- The correct accessible pattern is: define animation unconditionally (or inside `no-preference`), then suppress with `animation: none` inside `prefers-reduced-motion: reduce`
- This block appears to be an edit artefact — likely a skeleton left over from a planned animation that was never implemented

**Affected file:** `app/assets/stylesheets/errors.css` lines 49–53

## Proposed Solutions

### Option A — Delete lines 49–53 entirely (recommended)

Since no animation exists on `.error-code`, the entire block is dead code. Removing it has zero effect on rendered output and eliminates the misleading artefact.

### Option B — Implement the intended animation correctly

If a subtle fade-in or float animation on the large background error code was intended, implement it properly:

1. Define a `@keyframes` animation
2. Apply it to `.error-code` unconditionally
3. Suppress it inside `@media (prefers-reduced-motion: reduce)`

This requires a design decision on what the animation should be and is out of scope for a P3 cleanup ticket.

## Acceptance Criteria

- [ ] Lines 49–53 of `app/assets/stylesheets/errors.css` are deleted
- [ ] The 404 and 500 error pages render identically before and after the change (visual regression check)
- [ ] No CSS linting warnings remain related to this block

## Technical Details

| Field | Value |
|---|---|
| Affected file | `app/assets/stylesheets/errors.css` lines 49–53 |
| Root cause | Edit artefact — `animation: none` applied to `.error-code` which has no animation; media query condition also inverted |
| Rendered impact | None — `animation: none` on a non-animated element is a no-op |
| Semantic impact | Misleads future maintainers into thinking an animation exists or was intentionally suppressed |
| Severity | P3 — dead code / maintainability |
| Fix complexity | Trivial — delete 5 lines |
