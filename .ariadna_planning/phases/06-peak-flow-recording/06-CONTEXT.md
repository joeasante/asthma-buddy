# Phase 6: Peak Flow Recording - Context

**Gathered:** 2026-03-07
**Status:** Ready for planning

<domain>
## Phase Boundary

A logged-in user can manually enter a peak flow reading (numeric value + timestamp), set their personal best value, and have the system automatically compute and store a zone (Green / Yellow / Red) for each reading. Viewing readings with colour coding, editing, deleting, and trend charting are Phases 7 and 8.

</domain>

<decisions>
## Implementation Decisions

### Personal best setup flow
- Personal best lives in a **settings/profile page**, not on the entry form — it is a profile-level fact, not a per-reading value
- First time a user visits the peak flow entry form, show a contextual banner: "Set your personal best to see zone calculations" with a link to settings
- Users can log readings **without** a personal best set — zone is omitted or shown as "unknown" rather than blocking entry
- Personal best can be updated at any time from settings

### Personal best data model
- Store personal best as a **`personal_best_records` table** (`user_id`, `value`, `recorded_at`) — NOT a single column on `users`
- Current personal best = most recent record for the user
- Zone calculation uses the personal best value **at the time of the reading** (closest record with `recorded_at <= reading.recorded_at`), not today's value — this keeps historical zones accurate if personal best changes
- Phase 6 scope: model + settings form to create records only; history display is deferred to a future phase

### Entry form design
- Same structural pattern as the symptom form: same nav placement, same Turbo Stream submit behaviour, same "log" metaphor — feels like a sibling feature
- Visually distinct: large centred numeric input with unit label (L/min) — clinical and precise, contrasting with the symptom form's qualitative dropdowns
- Lives at its own route (`/peak_flow_readings/new` or equivalent)

### Zone feedback on submit
- Show the zone **immediately in the flash message** after saving: e.g. "Reading saved — Yellow Zone (68% of personal best)"
- If no personal best is set: "Reading saved — set your personal best to see your zone"
- Phase 7 handles colour-coded display in the readings list; this is the immediate per-submit feedback

### Personal best value guidance
- Plain numeric input with **helper text** beneath: "Your highest reading when your asthma is well controlled, as measured by your doctor or from your own history"
- No wizard, no auto-calculation
- **Validate range**: 100–900 L/min — outside this range is almost certainly a data entry error; show a clear inline validation error
- Unit label (L/min) displayed alongside the input field

### Claude's Discretion
- Exact layout and spacing of the entry form
- Flash message styling for zone feedback (colour chip vs plain text)
- Whether the personal best banner on the entry form is dismissible
- Turbo Stream vs full redirect on personal best save in settings

</decisions>

<specifics>
## Specific Ideas

- Zone calculation semantics: Green >= 80% of personal best, Yellow 50–79%, Red < 50% — as specified in the roadmap requirements
- Personal best history enables retrospective zone recalculation if personal best changes — a correctness advantage over a single-column approach

</specifics>

<deferred>
## Deferred Ideas

- Displaying personal best history (list of past personal best values with dates) — future phase
- Retrospective zone recalculation UI ("recalculate all zones") — future phase
- Guided personal best setup wizard — out of scope; helper text is sufficient for MVP

</deferred>

---

*Phase: 06-peak-flow-recording*
*Context gathered: 2026-03-07*
