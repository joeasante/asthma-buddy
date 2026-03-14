---
status: complete
priority: p1
issue_id: 349
tags: [code-review, database, data-integrity]
dependencies: []
---

## Problem Statement

The migration `add_column :medications, :dose_unit, :string, default: "puffs", null: false` sets every existing medication to "puffs" — including Prednisolone (tablets) and any other non-inhaler medications. This is clinically misleading.

## Findings

- `db/migrate/20260314121711_add_dose_unit_to_medications.rb` — blanket default of "puffs" applied to all rows
- `app/models/medication.rb` — medication_type enum distinguishes inhalers from tablets/other forms
- Medications with medication_type 3 (other) or 4 (tablet) should have dose_unit = "tablets" instead of "puffs"

## Proposed Solutions

A) **Create a new migration that updates existing tablet/other medications to "tablets" based on medication_type**
   - Pros: Safe for already-deployed environments, corrects existing data
   - Cons: Requires post-deploy verification queries

B) **Rewrite the original migration with conditional backfill (only possible if not yet deployed to production)**
   - Pros: Cleaner history
   - Cons: Only viable pre-production; requires checking deployment status first

C) **Add a rake task for one-time data correction**
   - Pros: Can be run independently of migrations, easy to audit
   - Cons: Manual step that could be forgotten

## Recommended Action



## Technical Details

**Affected files:**
- db/migrate/20260314121711_add_dose_unit_to_medications.rb
- app/models/medication.rb

## Acceptance Criteria

- [ ] Medications with medication_type 3 (other) or 4 (tablet) have dose_unit = "tablets"
- [ ] All other medications have dose_unit = "puffs"
- [ ] Verification SQL confirms no mismatched dose units
