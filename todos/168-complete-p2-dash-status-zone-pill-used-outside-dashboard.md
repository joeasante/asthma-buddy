---
status: pending
priority: p2
issue_id: "168"
tags: [code-review, css, design-system, show-pages]
dependencies: []
---

# dash-status-zone-pill Used on Peak Flow Show Page — Wrong Context, Wrong Contrast

## Problem Statement
`peak_flow_readings/show.html.erb` line 37 uses `class="dash-status-zone-pill"` with `style="display: inline-block;"`. This class is defined in `dashboard.css` as a component of the status hero card. Its zone colour overrides rely on parent selectors (`.dash-status--green .dash-status-zone-pill`, etc.). When used outside a `.dash-status` ancestor, those zone-coloured overrides never fire — the pill renders in its fallback state: white text on a white-overlay background designed for a teal hero card, not a white section-card. The inline `style="display: inline-block"` is a direct symptom of this context mismatch.

## Findings
- `dash-status-zone-pill` is a context-dependent component: its colours are set via `.dash-status--<zone> .dash-status-zone-pill` descendant selectors in `dashboard.css`
- Without the `.dash-status` parent, the pill renders with incorrect or invisible text
- A context-free zone badge class already exists: `zone-badge` with `zone-badge--<zone>` modifiers in `peak_flow.css`, handling all zone colours without requiring a parent element
- The inline `style="display: inline-block"` exists only to compensate for this class being the wrong choice here

## Proposed Solutions

### Option A
Replace `dash-status-zone-pill` with `zone-badge zone-badge--<%= zone %>` which is already defined in `peak_flow.css`, is context-free, and handles all zone colours correctly. Remove the `style="display: inline-block"` inline override — it is no longer needed.
- Pros: Uses the correct, already-existing component; eliminates the inline style; correct zone colours in all contexts; no new CSS required
- Cons: None
- Effort: Small
- Risk: Low

## Recommended Action

## Technical Details
- Affected files:
  - `app/views/peak_flow_readings/show.html.erb`

## Acceptance Criteria
- [ ] `dash-status-zone-pill` class removed from `peak_flow_readings/show.html.erb`
- [ ] Replaced with `zone-badge zone-badge--<%= zone %>` (or equivalent ERB interpolation)
- [ ] `style="display: inline-block"` inline override removed
- [ ] Zone pill renders with correct colour on the show page for all four zones (green, yellow, orange, red)

## Work Log
- 2026-03-10: Created via code review
