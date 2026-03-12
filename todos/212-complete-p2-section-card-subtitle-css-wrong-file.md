---
status: complete
priority: p2
issue_id: "212"
tags: [code-review, css, design-system, reliever-usage]
dependencies: []
---

# `.section-card-subtitle` Defined in Feature CSS — Should Be in `application.css`

## Problem Statement

`.section-card-subtitle` is defined in `app/assets/stylesheets/reliever_usage.css` (lines 98–103) but has no `reliever-` prefix, making it look like a shared utility. `application.css` already defines `.section-card-title` and `.section-card-header` as part of the section card component family. `.section-card-subtitle` belongs alongside them. Any future page trying to use this class will find nothing in `application.css` and silently get unstyled text.

## Findings

**Flagged by:** pattern-recognition-specialist (P2), code-simplicity-reviewer (P3)

**Location:** `app/assets/stylesheets/reliever_usage.css` lines 98–103

```css
.section-card-subtitle {
  margin-top: var(--space-sm);
  font-size: 0.875rem;
  color: var(--text-3);
  line-height: 1.5;
}
```

**Existing family in `application.css`:**
- `.section-card-title` (line ~1101)
- `.section-card-header` (line ~1111)

`.section-card-subtitle` is the natural third member of this family.

## Proposed Solutions

### Option A — Move to `application.css` (Recommended)
**Effort:** Trivial | **Risk:** None

1. Delete the rule from `reliever_usage.css`
2. Add to `application.css` alongside `.section-card-title`

No HTML changes needed — the class name stays the same.

### Option B — Rename to `.reliever-bar-insight` to make scope explicit
**Effort:** Trivial | **Risk:** Low (requires view change too)

If the styles are truly specific to the reliever feature's correlation card prose, rename to make that explicit:
```css
.reliever-bar-insight { ... }
```

**Pros:** Makes scope explicit. Feature CSS stays self-contained.
**Cons:** Misses the opportunity to add the class to the shared design system.

## Recommended Action

Option A. The name clearly signals a shared component. Moving it completes the `.section-card-*` family in `application.css`.

## Technical Details

- **Affected files:** `app/assets/stylesheets/reliever_usage.css`, `app/assets/stylesheets/application.css`
- **No HTML changes**

## Acceptance Criteria

- [ ] `.section-card-subtitle` is defined in `application.css` alongside `.section-card-title`
- [ ] Definition is removed from `reliever_usage.css`
- [ ] Visual appearance is unchanged

## Work Log

- 2026-03-10: Identified by pattern-recognition-specialist and code-simplicity-reviewer.
