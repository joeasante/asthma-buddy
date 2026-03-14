---
status: complete
priority: p1
issue_id: 348
tags: [code-review, database, schema]
dependencies: []
---

## Problem Statement

db/schema.rb does not reflect migration constraints for the `dose_unit` and `admin` columns. The `dose_unit` column shows `t.string "dose_unit"` but the migration specifies `default: "puffs", null: false`. The `admin` column shows `t.boolean "admin"` but should have `default: false, null: false`. Any environment bootstrapped from schema.rb gets wrong constraints.

## Findings

- `db/schema.rb` — `dose_unit` column missing `default: "puffs", null: false`
- `db/schema.rb` — `admin` column missing `default: false, null: false`
- `db/migrate/20260314121711_add_dose_unit_to_medications.rb` — migration specifies `default: "puffs", null: false`
- `db/migrate/20260313184514_add_admin_to_users.rb` — migration specifies `default: false, null: false`

## Proposed Solutions

A) **Run `bin/rails db:migrate` then `bin/rails db:schema:dump` to regenerate schema.rb**
   - Pros: Simple, correct, lets Rails generate the authoritative schema
   - Cons: None significant

B) **Manually edit schema.rb to add the constraints**
   - Pros: Quick
   - Cons: Fragile, schema.rb is auto-generated and manual edits can be overwritten

## Recommended Action



## Technical Details

**Affected files:**
- db/schema.rb
- db/migrate/20260314121711_add_dose_unit_to_medications.rb
- db/migrate/20260313184514_add_admin_to_users.rb

## Acceptance Criteria

- [ ] schema.rb shows `t.string "dose_unit", default: "puffs", null: false`
- [ ] schema.rb shows `t.boolean "admin", default: false, null: false`
