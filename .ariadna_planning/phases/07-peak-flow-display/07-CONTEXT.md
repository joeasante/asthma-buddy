# Phase 7 Context: Peak Flow Display and Management

## User Design Preferences

The user is not a graphic designer and defers on visual decisions. Requirements:
- **Good UX/UI** — follow best practices, not generic
- **WCAG 2.2 AA compliance** throughout all views
- **Accessible and usable** — keyboard navigable, screen-reader friendly

## Decisions

### Zone display style: Colored badge/pill (with background fill)
- Zone shown as a pill badge with background colour (Green/Yellow/Red)
- Must meet WCAG 2.2 AA contrast ratios (4.5:1 for text, 3:1 for non-text UI)
- Matches Phase 5 severity chip pattern for visual consistency
- Rationale: Most scannable at a glance without requiring zone name comprehension

### Edit pattern: Inline Turbo Frame
- Follow Phase 4 (symptom management) pattern — inline edit in place
- No separate edit page

### Delete pattern: Turbo Stream destroy
- Follow Phase 4 pattern — button_to with Turbo Stream response
- No confirmation modal (consistent with Phase 4)

### Index layout: Reverse-chronological list
- Match Phase 5 symptom timeline structure
- Date filter already implemented in controller (start_date / end_date params, 30-day default)
- Compact rows, zone badge prominent, value and timestamp visible at a glance

## Claude's Discretion (planner decides)
- Specific colour values for zone badges (must pass WCAG contrast checks)
- Exact CSS class naming for badge vs label distinction
- Whether pagination is needed (Phase 5 used 25/page — planner may choose same or simple load-more)
- How the index row looks in detail (layout, spacing, typography)

## Out of Scope
- Trend charts (Phase 8)
- New reading entry form (Phase 6 — already built)
- Personal best settings (Phase 6 — already built)
