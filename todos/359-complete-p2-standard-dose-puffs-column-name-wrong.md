---
status: complete
priority: p2
issue_id: 359
tags: [code-review, naming, database]
dependencies: []
---

## Problem Statement

The column `standard_dose_puffs` now stores dose amounts for puffs, tablets, AND ml — but the name still says "puffs". Same issue with `sick_day_dose_puffs`. This will confuse future developers.

## Findings

In `app/models/medication.rb` and `db/schema.rb`, the columns `standard_dose_puffs` and `sick_day_dose_puffs` were originally named when the only dose unit was puffs. Now that the application supports tablets and ml as dose units, these columns store generic dose amounts but retain the misleading "puffs" suffix. This creates confusion for anyone reading the schema or model without historical context.

## Proposed Solutions

**A) Rename columns to `standard_dose_amount` and `sick_day_dose_amount` via migration with alias for backward compat**
- Pros: Clean, self-documenting schema; no ambiguity for new developers
- Cons: Requires migration; all references in models, controllers, views, and tests must be updated; need alias methods during transition

**B) Add a comment explaining the naming mismatch**
- Pros: Quick; no migration needed
- Cons: Still confusing; comments can become stale; doesn't fix the root issue

## Recommended Action



## Technical Details

**Affected files:**
- `app/models/medication.rb`
- `db/schema.rb`
- All views, controllers, and tests referencing `standard_dose_puffs` or `sick_day_dose_puffs`

## Acceptance Criteria

- [ ] Column name reflects its actual purpose (dose amount, not puffs)
- [ ] All references updated
