---
status: pending
priority: p3
issue_id: "267"
tags: [code-review, css, style]
dependencies: []
---

# CSS Modifier Classes Use `snake_case` Instead of Project `kebab-case` Convention

## Problem Statement

The BEM modifier classes `.notification-icon--low_stock` and `.notification-icon--missed_dose` in `notifications.css` use underscores in the modifier segment. The project CSS convention for BEM modifiers uses kebab-case: `.medication-badge--preventer`, `.adherence-cell--on_track`. Fixing this requires changing both the CSS class names and the ERB template that interpolates `notification_type` directly into the class attribute.

## Findings

`app/assets/stylesheets/notifications.css` lines 50–60:

```css
.notification-icon--low_stock {
  background-color: var(--color-warning-bg);
  color: var(--color-warning);
}

.notification-icon--missed_dose {
  background-color: var(--color-danger-bg);
  color: var(--color-danger);
}
```

The ERB partial that generates these class names (`app/views/notifications/_notification.html.erb`) interpolates the enum value directly:

```erb
<div class="notification-icon notification-icon--<%= notification.notification_type %>">
```

`notification.notification_type` returns `"low_stock"` or `"missed_dose"` (Rails enum string) — both use underscores, which is why the CSS was written to match. Fixing the CSS requires a corresponding fix in the template.

Project kebab-case BEM modifier examples from other stylesheets:

```css
/* settings.css */
.medication-badge--preventer { ... }
.medication-badge--reliever  { ... }

/* symptom_timeline.css */
.adherence-cell--on_track    { ... }  ← note: this one also uses underscore (inconsistency)
```

Confirmed by: kieran-rails-reviewer.

## Proposed Solutions

### Option A — Dasherize in the ERB template and update CSS *(Recommended)*

In `app/views/notifications/_notification.html.erb`:

```erb
<div class="notification-icon notification-icon--<%= notification.notification_type.dasherize %>">
```

In `app/assets/stylesheets/notifications.css`:

```css
.notification-icon--low-stock {
  background-color: var(--color-warning-bg);
  color: var(--color-warning);
}

.notification-icon--missed-dose {
  background-color: var(--color-danger-bg);
  color: var(--color-danger);
}
```

Pros: consistent with project kebab-case BEM convention; `String#dasherize` is a standard Rails/ActiveSupport method
Cons: requires coordinated change to both CSS and template

### Option B — Add a helper method on the model

```ruby
# app/models/notification.rb
def type_css_modifier
  notification_type.dasherize
end
```

```erb
<div class="notification-icon notification-icon--<%= notification.type_css_modifier %>">
```

Pros: keeps template clean; logic is testable
Cons: slightly more code for a trivial transformation; `dasherize` inline is already readable

## Recommended Action

Option A — use `dasherize` inline in the template and update the CSS class names. It is the smallest targeted fix.

## Technical Details

- **Affected files:**
  - `app/assets/stylesheets/notifications.css` lines 50–60
  - `app/views/notifications/_notification.html.erb` (class interpolation line)

## Acceptance Criteria

- [ ] `.notification-icon--low-stock` and `.notification-icon--missed-dose` are the CSS class names
- [ ] No `low_stock` or `missed_dose` underscore variants remain in `notifications.css`
- [ ] The ERB template produces the correct kebab-case class names at runtime
- [ ] Notification icons still render with the correct warning / danger colour tokens

## Work Log

- 2026-03-11: Found by kieran-rails-reviewer during Phase 19 code review
