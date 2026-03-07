---
status: pending
priority: p3
issue_id: "101"
tags: [code-review, css, peak-flow]
dependencies: []
---

# `btn-primary` class used in index view has no CSS definition

## Problem Statement

`index.html.erb` uses `class: "btn-primary"` on the "Log a reading" link, but no `.btn-primary` rule exists in any stylesheet (`peak_flow.css`, `symptom_timeline.css`, `settings.css`, `application.css`). The link renders unstyled. `btn-edit` and `btn-delete` are also undefined but mirror the reference pattern (`_timeline_row.html.erb`) — `btn-primary` is novel and orphaned.

## Findings

**Flagged by:** pattern-recognition-specialist (P3)

**Location:** `app/views/peak_flow_readings/index.html.erb:5`

```erb
<%= link_to "Log a reading", new_peak_flow_reading_path, class: "btn-primary" %>
```

No matching CSS rule found in any stylesheet.

## Proposed Solutions

### Option A: Add `.btn-primary` to a global stylesheet

```css
/* app/assets/stylesheets/application.css */
.btn-primary {
  display: inline-block;
  padding: 0.5rem 1rem;
  background-color: var(--color-primary, #0070f3);
  color: #fff;
  border-radius: 4px;
  text-decoration: none;
  font-weight: 600;
}
```

- **Effort:** Small
- **Risk:** None

### Option B: Use an existing class or add `btn-primary` to `peak_flow.css`

If a global button system doesn't yet exist, add to `peak_flow.css` temporarily and note it as a candidate for extraction.

## Recommended Action

Option A if a global button design system is planned; Option B as a temporary fix.

## Technical Details

- **Affected files:** `app/assets/stylesheets/application.css` or `peak_flow.css`

## Acceptance Criteria

- [ ] "Log a reading" link renders with visible button styling
- [ ] `.btn-primary` CSS rule exists in a discoverable stylesheet

## Work Log

- 2026-03-07: Identified during Phase 7 code review
