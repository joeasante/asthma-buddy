# Phase 3 Context: Symptom Recording

**Gathered:** 2026-03-06 (inline during plan-phase)

## Decisions (Locked)

- **Symptom types enum:** `wheezing`, `coughing`, `shortness_of_breath`, `chest_tightness` (standard 4)
- **Severity enum:** `mild`, `moderate`, `severe` (3-level scale)
- **Turbo approach:** Turbo Stream — form clears on success, new entry streams into a list displayed below the form; form stays visible on the same page
- **Notes field:** Lexxy for rich text (decided in project state, carried into Phase 3)

## Claude's Discretion

- Model naming and column names (e.g. `symptom_type` vs `kind` for the enum column)
- How the "list below form" is structured (partial, dom_id convention)
- Turbo Stream response details (append vs prepend, frame ID naming)
- Controller action count and route structure

## Deferred Ideas

- Severity scale beyond 3 levels (numeric 1-5, very_severe tier)
- Additional symptom types beyond the standard 4
- Filtering/sorting on the inline list (that's Phase 5)
- Edit/delete from the inline list (that's Phase 4)
