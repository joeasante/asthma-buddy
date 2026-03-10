---
status: pending
priority: p2
issue_id: "228"
tags: [frontend, css, code-review, ui]
dependencies: []
---

# `field-input--danger` CSS Modifier Is Undefined — Account Deletion Confirmation Input Has No Styling

## Problem Statement

The account deletion confirmation text field in `settings/show.html.erb` uses `class: "field-input field-input--danger"`. Neither `.field-input` nor `.field-input--danger` have CSS definitions in any stylesheet. The field renders with browser-default styling, with no visual indication that this is a danger-state input.

The existing error-state class in the codebase is `field-input--error` (used in `peak_flow_readings/_form.html.erb`). The `--danger` modifier is both inconsistent with the existing naming convention and completely unstyled.

## Findings

**Flagged by:** pattern-recognition-specialist

**Location:** `app/views/settings/show.html.erb` line 55

**Verified absent from:** `app/assets/stylesheets/application.css`, `app/assets/stylesheets/settings.css`, and all other stylesheets in the pipeline.

**Existing convention:** `.field-input--error` is the defined modifier for invalid/error states, used in `app/views/peak_flow_readings/_form.html.erb`.

## Proposed Solutions

### Option A — Replace with Existing `field-input--error` Modifier

Replace `field-input--danger` with `field-input--error` in the confirmation field's class attribute:

```erb
class: "field-input field-input--error"
```

**Pros:** Uses a defined, consistent class; no new CSS required; immediately styled.
**Cons:** `--error` semantics imply a validation error has occurred, which is slightly different from a "danger zone" affordance. May be acceptable if the visual appearance is appropriate.
**Effort:** Trivial
**Risk:** None

### Option B — Define `.field-input` Base and `.field-input--danger` Modifier in settings.css

Add CSS to `app/assets/stylesheets/settings.css`:

```css
.field-input {
  display: block;
  width: 100%;
  padding: var(--space-2) var(--space-3);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  font-size: var(--text-sm);
  line-height: var(--leading-normal);
  background-color: var(--color-surface);
  color: var(--color-text);
  transition: border-color 0.15s ease, box-shadow 0.15s ease;
}

.field-input--danger {
  border-color: var(--color-danger);
  background-color: var(--color-danger-subtle, color-mix(in srgb, var(--color-danger) 8%, transparent));
}

.field-input--danger:focus {
  outline: none;
  border-color: var(--color-danger);
  box-shadow: 0 0 0 3px color-mix(in srgb, var(--color-danger) 20%, transparent);
}
```

**Pros:** Proper danger-zone affordance distinct from an error state; reusable for future danger zone inputs.
**Cons:** Requires defining `.field-input` base rules if not already defined globally (they are not).
**Effort:** Small
**Risk:** None

## Recommended Action

Option B if the design requires a visually distinct "danger zone" input appearance. Option A if `.field-input--error` styling is visually appropriate and the semantic distinction between error and danger does not matter for this context.

## Technical Details

**Affected files:**
- `app/views/settings/show.html.erb`
- `app/assets/stylesheets/settings.css` (if adding new CSS definitions)

**Acceptance Criteria:**
- [ ] The confirmation text field has a defined CSS style (either via existing modifier or new definition)
- [ ] No undefined CSS class references on the danger zone form inputs

## Work Log

- 2026-03-10: Identified by pattern-recognition-specialist in Phase 16 code review.
