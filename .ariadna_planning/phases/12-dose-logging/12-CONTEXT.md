# Phase 12: Dose Logging — Context

**Gathered:** 2026-03-08 (inline, pre-planning)

---

## Decisions

### Dose log form placement
**Decision:** Inline on each medication card — collapsible/inline form within the existing medications index (`/settings/medications`).
**Rationale:** No medication show page (deferred in Phase 11); consistent with the inline-edit pattern already established. Avoids building a new page.
**Implication for planner:** DoseLogsController#create scoped from the medication card in the index view. No `show` action needed on MedicationsController.

### Dose history display
**Decision:** Inline on the card — compact list of last 3–5 dose log entries shown directly on the medication card.
**Rationale:** Keeps everything on one page; consistent with the card-first design.
**Implication for planner:** DoseLog records rendered within the medication card partial. Eager-load `dose_logs` on the index query to avoid N+1.

### Timestamp input
**Decision:** Default to now (pre-filled), with an optional datetime override visible in the form.
**Rationale:** One-tap log with minimal friction; user can correct if logging retroactively.
**Implication for planner:** `recorded_at` defaults to `Time.current` in the form; datetime_field shown but pre-filled. DoseLog model accepts the field.

---

## Deferred / Out of Scope

- Full dose history page per medication — show page is still deferred; the compact inline history (3–5 entries) is sufficient for Phase 12
- Dose editing — users can delete and re-log; no edit action needed
