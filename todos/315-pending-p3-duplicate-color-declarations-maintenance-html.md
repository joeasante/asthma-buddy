---
status: pending
priority: p3
issue_id: 315
tags: [code-review, css, dead-code, maintenance]
---

# 315 — P3 — Duplicate color declarations in maintenance.html

## Problem Statement

`public/maintenance.html` contains duplicate `color:` declarations in two CSS rule blocks. In `.maintenance-body` (lines 86–87) and `.maintenance-contact` (lines 102–103), the value `color: #5eead4` is set on one line and immediately overridden by `color: #0f766e` on the very next line within the same rule block. The first declaration in each case is dead — the browser reads both but the second value always wins. These are edit artefacts from a colour adjustment pass where the original value was not removed after being updated.

`#5eead4` is a light teal (Tailwind `teal-300`); `#0f766e` is a darker teal (Tailwind `teal-700`). The intended value is clearly `#0f766e`, which matches the darker body-text treatment used consistently in the rest of the file. The stale `#5eead4` declarations add noise and create a false impression that there is intentional cascade layering.

## Findings

- `public/maintenance.html` lines 82–89, `.maintenance-body` rule block:

```css
.maintenance-body {
  font-size: 1rem;
  font-weight: 700;
  line-height: 1.7;
  color: #5eead4;   /* line 86 — dead, immediately overridden */
  color: #0f766e;   /* line 87 — effective value */
  margin-bottom: 2rem;
}
```

- `public/maintenance.html` lines 99–104, `.maintenance-contact` rule block:

```css
.maintenance-contact {
  font-size: 0.875rem;
  font-weight: 700;
  color: #5eead4;   /* line 102 — dead, immediately overridden */
  color: #0f766e;   /* line 103 — effective value */
}
```

- `#5eead4` (teal-300) is a light, low-contrast colour that would be illegible on the `#f0fdfa` (teal-50) background used by the page — it would fail WCAG AA contrast requirements if rendered. The correct `#0f766e` (teal-700) passes contrast.
- The maintenance page is a standalone static HTML file with no Rails pipeline dependency — it must be edited directly

**Affected file:** `public/maintenance.html` lines 86 and 102

## Proposed Solutions

### Option A — Delete the first `color:` declaration in each block (recommended)

Remove line 86 (`color: #5eead4;`) from `.maintenance-body` and line 102 (`color: #5eead4;`) from `.maintenance-contact`. This leaves the effective value `color: #0f766e` in each block and removes the dead declarations.

### Option B — CSS variable alignment

If the project ever adds design tokens to the maintenance page (unlikely given it is intentionally standalone), both declarations would be replaced with a single variable reference. Not recommended for this ticket.

## Acceptance Criteria

- [ ] `color: #5eead4` is removed from the `.maintenance-body` rule block (only `color: #0f766e` remains)
- [ ] `color: #5eead4` is removed from the `.maintenance-contact` rule block (only `color: #0f766e` remains)
- [ ] The maintenance page renders identically before and after (visual check in browser)
- [ ] No remaining duplicate property declarations in the inline `<style>` block of `public/maintenance.html`

## Technical Details

| Field | Value |
|---|---|
| Affected file | `public/maintenance.html` lines 86, 102 |
| Root cause | Edit artefact — original colour value not removed after being updated on the next line |
| Rendered impact | None — duplicate CSS properties; last declaration wins |
| Contrast risk | `#5eead4` on `#f0fdfa` would fail WCAG AA if it were ever the effective value; the current effective `#0f766e` passes |
| Severity | P3 — dead code / maintainability |
| Fix complexity | Trivial — delete one line in each of two rule blocks |
