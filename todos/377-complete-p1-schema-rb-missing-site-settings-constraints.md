---
status: pending
priority: p1
issue_id: "377"
tags: [code-review, database, rails]
dependencies: []
---

## Problem Statement
Migration creates `site_settings.key` with `null: false` and a unique index, but neither constraint appears in schema.rb or the actual database (confirmed via PRAGMA). Any `db:schema:load` (CI, new dev) creates the table without constraints, allowing NULL keys and duplicate rows. `find_or_create_by!` in toggle_registration! is vulnerable to race-condition duplicates without the unique index.

## Findings
`PRAGMA table_info(site_settings)` shows the `key` column with `notnull=0`, and no unique index exists on the column in `sqlite_master`. The original migration may have been run with errors silently swallowed, or schema.rb was dumped from a database state that predates the constraints. Any environment bootstrapped via `db:schema:load` inherits the broken schema.

## Proposed Solutions
### Option A: Create corrective migration adding constraints then re-dump schema
- Add `change_column_null :site_settings, :key, false` and `add_index :site_settings, :key, unique: true, if_not_exists: true`, then re-dump schema
- Pros: clean fix, forward-compatible
- Cons: extra migration
- Effort: Small
- Risk: Low

### Option B: Drop and recreate site_settings table in a new migration
- Pros: clean slate
- Cons: data loss if any settings exist
- Effort: Small
- Risk: Medium

## Acceptance Criteria
- [ ] `PRAGMA table_info(site_settings)` shows key with notnull=1
- [ ] `SELECT sql FROM sqlite_master WHERE type='index' AND tbl_name='site_settings'` shows unique index
- [ ] schema.rb reflects both NOT NULL constraint and unique index on key
