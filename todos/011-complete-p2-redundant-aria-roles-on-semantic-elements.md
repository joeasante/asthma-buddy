---
status: pending
priority: p2
issue_id: "011"
tags: [code-review, accessibility, html, patterns]
dependencies: ["001"]
---

# Redundant Explicit ARIA Roles on Semantic Landmark Elements

## Problem Statement

The application layout adds explicit `role=` attributes to semantic HTML5 elements that already carry those roles implicitly. `<header role="banner">`, `<nav role="navigation">`, `<main role="main">`, and `<footer role="contentinfo">` are all redundant per the ARIA in HTML specification. The problem is not correctness today but pattern propagation: if developers follow this convention they will also write `<div role="banner">` (where explicit role IS needed) with no visual distinction from elements where it is implicit. This erodes the signal value of ARIA roles.

The integration test and system test both assert on `header[role=banner]` and `main[role=main]`, which will break if/when the roles are cleaned up — creating a perverse incentive to keep incorrect markup.

## Findings

**Flagged by:** pattern-recognition-specialist

**Location:** `app/views/layouts/application.html.erb`

| Element | Redundant Role | Keeper Attribute |
|---------|---------------|------------------|
| `<header role="banner">` | `role="banner"` — implicit | — |
| `<nav role="navigation" aria-label="Main navigation">` | `role="navigation"` — implicit | `aria-label` — keep |
| `<main role="main" id="main-content">` | `role="main"` — implicit | `id="main-content"` — keep for skip link |
| `<footer role="contentinfo">` | `role="contentinfo"` — implicit | — |

## Proposed Solutions

### Option A — Remove redundant roles, update tests (Recommended)
```erb
<header>
<nav aria-label="Main navigation">
<main id="main-content">
<footer>
```

Update test selectors:
- `assert_select "header[role=banner]"` → `assert_select "header"`
- `assert_select "main[role=main]"` → `assert_select "main#main-content"`
- `assert_selector "header[role=banner]"` → `assert_selector "header"`
- `assert_selector "nav[role=navigation]"` → `assert_selector "nav"`

**Effort:** Small
**Risk:** None

### Option B — Keep as-is
Explicit roles are spec-valid (though redundant). Accessibility tools accept them. Leave for a future cleanup pass.

**Effort:** None
**Risk:** Pattern propagation

## Recommended Action

Option A — clean up before the layout is used as a template for Phase 2 views.

## Technical Details

**Affected files:**
- `app/views/layouts/application.html.erb`
- `test/controllers/home_controller_test.rb`
- `test/system/home_test.rb`

**Acceptance Criteria:**
- [ ] No redundant `role=` attributes on semantic landmark elements
- [ ] `aria-label="Main navigation"` retained on `<nav>`
- [ ] `id="main-content"` retained on `<main>`
- [ ] All tests updated and passing

## Work Log

- 2026-03-06: Identified by pattern-recognition-specialist. Dependency: fix nested `<main>` (001) first.
