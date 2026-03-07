---
status: pending
priority: p2
issue_id: "078"
tags: [code-review, performance, database, rails]
dependencies: []
---

# Missing Covering Index on `personal_best_records` for Point-in-Time Lookup

## Problem Statement

`PeakFlowReading#personal_best_at_reading_time` fires on every `create` (via `before_save`) and again when computing `zone_percentage`. The query is:

```sql
SELECT value FROM personal_best_records
WHERE user_id = ? AND recorded_at <= ?
ORDER BY recorded_at DESC LIMIT 1
```

The existing index `(user_id, recorded_at)` covers the `WHERE` and `ORDER BY` but does not include `value`. SQLite must perform a table heap fetch to retrieve the `value` column after the index lookup. A covering index `(user_id, recorded_at, value)` eliminates the heap fetch entirely — the query is fully answered from the index B-tree.

## Findings

**Flagged by:** performance-oracle (P1-B)

**Existing index** (`db/schema.rb`):
```ruby
t.index ["user_id", "recorded_at"], name: "index_personal_best_records_on_user_id_and_recorded_at"
```

**Query issued by `personal_best_at_reading_time`:**
```ruby
user.personal_best_records
    .where("recorded_at <= ?", recorded_at)
    .order(recorded_at: :desc)
    .pick(:value)
```

The `pick(:value)` fetches only the `value` column. With a covering index, the DB can satisfy this query entirely from the index without touching the table rows.

## Proposed Solutions

### Option A: Add covering index migration (Recommended)
**Effort:** Small | **Risk:** Very Low

```ruby
# db/migrate/TIMESTAMP_add_covering_index_to_personal_best_records.rb
class AddCoveringIndexToPersonalBestRecords < ActiveRecord::Migration[8.1]
  def change
    add_index :personal_best_records,
              [:user_id, :recorded_at, :value],
              name: "index_personal_best_records_covering"
  end
end
```

The existing `(user_id, recorded_at)` index supports the `current_for` query (SELECT * ORDER BY recorded_at DESC LIMIT 1) — keep it. Add the covering index for the `personal_best_at_reading_time` query.

## Recommended Action

Add the covering index. Zero code change, one migration, measurable improvement on every peak flow create.

## Technical Details

**Affected files:**
- New migration file

## Acceptance Criteria

- [ ] Migration runs successfully: `bin/rails db:migrate`
- [ ] `db/schema.rb` shows `index_personal_best_records_covering` with `[:user_id, :recorded_at, :value]`
- [ ] `bin/rails test` passes with 0 failures

## Work Log

- 2026-03-07: Identified by performance-oracle in Phase 6 code review
