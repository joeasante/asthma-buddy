---
status: complete
priority: p3
issue_id: 375
tags: [code-review, database]
dependencies: []
---

## Problem Statement

The `dose_unit` column stores string enum values but has no database-level CHECK constraint. Any raw SQL insert or update could write invalid values. Risk is low since all writes go through the model's validation, but a DB constraint adds defense in depth.

## Findings

The migration that added `dose_unit` to the medications table defines it as a string column without a CHECK constraint. While the ActiveRecord model validates the value, direct SQL access (migrations, console, data fixes) could insert invalid strings, leading to unexpected behavior in `dose_unit_label` and other code that assumes valid enum values.

## Proposed Solutions

- Add a new migration with a CHECK constraint: `CHECK(dose_unit IN ('puffs', 'mcg', 'ml'))` (or whatever the valid values are).
- For SQLite, this can be done via a raw SQL `ALTER TABLE` or by using `add_check_constraint` if supported.
- Alternatively, document that this is accepted risk given all writes go through the model.

## Technical Details

**Affected files:** db/migrate/20260314121711_add_dose_unit_to_medications.rb

## Acceptance Criteria

- [ ] CHECK constraint added to `dose_unit` column limiting values to valid enum options
- [ ] Migration runs successfully on both development and production SQLite databases
- [ ] Existing records pass the constraint (no data violations)
- [ ] Attempting to insert an invalid `dose_unit` via raw SQL raises a constraint error
