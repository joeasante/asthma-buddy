# Phase 4: Symptom Management - Context

**Gathered:** 2026-03-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Users can edit or delete any symptom entry they previously recorded. The only new capabilities are edit and delete — symptom display and recording are Phase 3. Ownership enforcement (a user cannot touch another user's entries) is a hard requirement carried from the multi-user isolation constraint established in Phase 3.

</domain>

<decisions>
## Implementation Decisions

### Edit experience
- Inline editing via Turbo Frame — clicking "Edit" replaces the list entry with a form in place
- No page navigation away from the list; form collapses back to the updated entry on save
- Consistent with Phase 3's Turbo Stream approach; no new navigation patterns introduced

### Delete UX
- `data-turbo-confirm` on the delete button — browser-native confirm dialog ("Delete this entry?")
- On confirm, entry removed via Turbo Stream (no extra page, no redirect)
- Simple and zero-friction; no separate confirmation page

### Post-action feedback
- Edit: Turbo Stream replaces the entry element with updated content + flash notice
- Delete: Turbo Stream removes the entry from the DOM + flash notice
- No redirects in either case — instant visual feedback, stay on the list

### Entry access point
- No separate show/detail page — edit and delete actions live directly on each list entry
- Buttons visible on each entry (always visible on mobile, hover-revealed on desktop is fine)
- The list is the primary interface; no need to navigate into a detail view to manage an entry

### Claude's Discretion
- Exact button placement and styling within each entry (pencil icon, text label, or both)
- CSS hover behaviour on desktop
- Flash message wording

</decisions>

<specifics>
## Specific Ideas

- Follow Rails 8 Omakase conventions throughout — ERB, Turbo, no heavy JS
- Pattern should feel consistent with the Phase 3 create flow (Turbo Stream, 422 on validation failure)

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 04-symptom-management*
*Context gathered: 2026-03-07*
