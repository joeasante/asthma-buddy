# Phase 13 Context: Dose Tracking & Low Stock

**Gathered:** 2026-03-08 (inline context, quick discussion)

---

## Decisions

### Refill UX
**Decision:** One-click with editable default (pre-filled form).

Show a small inline form pre-filled with the medication's original `starting_dose_count`. User can accept (one click) or adjust the number before submitting. Avoids friction for the common case while supporting exceptions (different batch size).

- Implementation: Turbo Frame toggles between "Refill" button and a small inline form pre-filled with the original count
- On submit: updates `starting_dose_count` to the new value and sets `refilled_at = Time.current`

### Dashboard Low-Stock Warning
**Decision:** Inline within a "Medications" section/card on the dashboard.

A dedicated "Medications" card on the dashboard (similar pattern to existing cards) lists medications with low stock inline — each with a warning badge. No full-width alert banner (too intrusive). Only appears when at least one medication is low on stock.

- If no medications are low: the "Medications" section is hidden or shows nothing
- If any medications are low: show a card with the affected medications and a "Refill" link each

### Remaining Dose Display (No Schedule)
**Decision:** Show raw count only — always display "N doses remaining", omit the days-of-supply estimate when `doses_per_day` is blank.

- Reliever inhalers have no schedule but users need to know remaining doses (safety critical)
- Display: "N doses remaining" (no days estimate)
- Only show "~X days remaining" when `doses_per_day` is present

---

## Claude's Discretion

- Exact CSS styling / class names for low-stock warning badge
- Whether low-stock threshold is a constant or configurable (use constant: `LOW_STOCK_DAYS = 14`)
- How the inline refill form is revealed (Turbo Frame or Stimulus toggle)
- Dashboard card placement (after peak flow section, before or after where Phase 14 adherence card will go)

---

## Deferred Ideas

- Push notifications for low stock
- Configurable low-stock threshold per medication
- Scan barcode to auto-fill refill count
