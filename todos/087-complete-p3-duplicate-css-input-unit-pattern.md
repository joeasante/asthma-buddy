---
status: pending
priority: p3
issue_id: "087"
tags: [code-review, css, consistency, rails]
dependencies: []
---

# Duplicate CSS Naming for Same Structural Pattern (Input + Unit Label)

## Problem Statement

Both the peak flow form and the settings personal best form render an input field paired with a "L/min" unit label (a flex row containing a number input and a unit span). The settings form uses `.input-with-unit` / `.input-unit` (generic, reusable). The peak flow form uses `.peak-flow-value-input-row` / `.peak-flow-unit` (feature-prefixed, non-reusable). Same visual pattern, two different naming families.

## Findings

**Flagged by:** pattern-recognition-specialist (P2-1)

**Settings form** (`app/views/settings/_personal_best_form.html.erb`):
```erb
<div class="input-with-unit">
  <%= form.number_field :value, ... %>
  <span class="input-unit" aria-hidden="true">L/min</span>
</div>
```

**Peak flow form** (`app/views/peak_flow_readings/_form.html.erb`):
```erb
<div class="peak-flow-value-input-row">
  <%= form.number_field :value, ... %>
  <span class="peak-flow-unit" aria-hidden="true">L/min</span>
</div>
```

## Proposed Solutions

### Option A: Use `.input-with-unit` / `.input-unit` in peak flow form too (Recommended)
**Effort:** Small | **Risk:** Low

Update `_form.html.erb` to use the generic class names. Move any peak-flow-specific layout tweaks from `.peak-flow-value-input-row` in `peak_flow.css` to the generic `.input-with-unit` in `application.css` (if they differ), or simply delete the duplicate CSS.

### Option B: Document the naming families
**Effort:** Tiny | **Risk:** Very Low

Add a CSS comment noting the two patterns exist and when to use each. Acceptable if the visual styles genuinely differ and should be maintained separately.

## Recommended Action

Option A — consolidate on `.input-with-unit` / `.input-unit`. The generic names are already established by the settings form. Using them in the peak flow form removes a naming family with no unique styles.

## Technical Details

**Affected files:**
- `app/views/peak_flow_readings/_form.html.erb`
- `app/assets/stylesheets/peak_flow.css`

## Acceptance Criteria

- [ ] Peak flow form uses `.input-with-unit` wrapper and `.input-unit` span
- [ ] Duplicate CSS rules removed from `peak_flow.css`
- [ ] Visual appearance unchanged
- [ ] `bin/rails test` passes with 0 failures

## Work Log

- 2026-03-07: Identified by pattern-recognition-specialist in Phase 6 code review
