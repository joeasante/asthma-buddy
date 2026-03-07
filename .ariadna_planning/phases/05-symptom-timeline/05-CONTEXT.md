# Phase 5: Symptom Timeline - Context

**Gathered:** 2026-03-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Display a user's full symptom history in reverse-chronological order, filterable by date range, with a severity trend summary. Recording, editing, and deleting entries are handled in earlier phases — this phase is read-only presentation and filtering only.

</domain>

<decisions>
## Implementation Decisions

### Entry layout
- Compact rows, not cards — density enables pattern scanning
- Left edge: colored severity indicator bar (visual primary signal)
- Row content: symptom type + severity label + timestamp
- Notes: truncated one-line preview (~60 chars, fading out) shown inline — no expand interaction needed

### Date filter
- Preset chips: "7 days / 30 days / 90 days / All" — covers doctor-visit prep scenarios
- Custom start/end date inputs as fallback for arbitrary ranges
- Filter sits above the list
- Updates via Turbo Frame — no full page reload on mobile
- Active chip is highlighted so the user always knows the active range

### Severity trend summary
- Horizontal stacked bar (Mild | Moderate | Severe, color coded) above the list
- Raw counts shown as labels within the bar segments
- Updates when the date filter changes
- Positioned above the entry list so pattern is visible before reading entries

### Pagination
- 25 entries per page
- Simple Prev / Next navigation with page position indicator ("Page 2 of 8")
- No infinite scroll — users need spatial navigation to find specific dates

### Claude's Discretion
- Exact color values for severity indicator (should match zone colors used in peak flow phases for visual consistency)
- Responsive breakpoints and row spacing
- Timestamp format (relative "2 days ago" vs absolute "Mar 5, 2:14 PM" — pick what's clearest for health context)
- Empty state copy and illustration

</decisions>

<specifics>
## Specific Ideas

- Severity color language should be consistent with peak flow zones (Green / Yellow / Red) introduced in Phase 6 — establish the palette here so it carries forward
- Primary use case is mobile, logged while symptomatic — compact rows and Turbo updates are non-negotiable for this reason

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 05-symptom-timeline*
*Context gathered: 2026-03-07*
