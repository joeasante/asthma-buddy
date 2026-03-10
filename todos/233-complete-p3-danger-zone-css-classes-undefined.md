---
status: pending
priority: p3
issue_id: "233"
tags: [code-review, css, frontend]
dependencies: []
---

# `danger-zone-*` CSS classes in settings/show.html.erb have no backing stylesheet rules

## Problem Statement

`settings/show.html.erb` uses `.danger-zone`, `.danger-zone-heading`, `.danger-zone-body`, `.danger-zone-description`, `.danger-zone-action-title`, `.danger-zone-action-description`. None of these have CSS rules in any stylesheet. The section renders solely with `section-card--danger` styling and browser defaults. The BEM class names are effectively semantic-only identifiers with no visual output. Whether intentional or an oversight, this should be documented or CSS should be added.

## Findings

**Flagged by:** phase-16-code-reviewer

**Location:** `app/views/settings/show.html.erb`, `app/assets/stylesheets/settings.css`

## Proposed Solutions

### Option A — Add CSS rules for the danger-zone classes

Add `.danger-zone` layout rules to `settings.css`, giving the section proper spacing, heading typography, and a flexbox/grid body layout to separate the description from the form. Example structure:

```css
.danger-zone { /* outer padding/margin */ }
.danger-zone-heading { /* heading size, colour, weight */ }
.danger-zone-body { /* flex or grid, gap */ }
.danger-zone-description { /* flex-basis, prose max-width */ }
.danger-zone-action-title { /* subheading size */ }
.danger-zone-action-description { /* muted colour, small size */ }
```

**Effort:** Low
**Risk:** Visual — review rendering after applying rules

### Option B — Remove unused class names from the HTML

If the `section-card--danger` appearance is sufficient and no layout CSS is planned, strip the dangling class names to reduce markup noise.

**Effort:** Trivial
**Risk:** None

## Recommended Action

Decide intentionally: if the danger zone layout should be improved (description beside the form, structured heading hierarchy), go with Option A. If the card border colouring is sufficient, go with Option B. Either is better than the current ambiguous state.

## Technical Details

**Acceptance Criteria:**
- [ ] Either CSS rules exist for `.danger-zone-*` classes, or classes without CSS purpose are removed

## Work Log

- 2026-03-10: Identified by phase-16-code-reviewer.
