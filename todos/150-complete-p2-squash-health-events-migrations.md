---
status: pending
priority: p2
issue_id: "150"
tags: [code-review, rails, migrations, health-events]
dependencies: []
---

# Squash Two Health Events Migrations Into One

## Problem Statement

`health_events` is a brand-new table that was created with two migrations written in the same session — `20260309000001_create_health_events.rb` (without `ended_at`) and `20260309000002_add_ended_at_to_health_events.rb`. The `ended_at` column is a core domain concept, not a post-hoc addition. Two migrations for a table that never existed in production adds noise and implies a change of requirements that didn't happen.

## Findings

**Flagged by:** kieran-rails-reviewer (P1), architecture-strategist (P3)

**Location:**
- `db/migrate/20260309000001_create_health_events.rb`
- `db/migrate/20260309000002_add_ended_at_to_health_events.rb`

Both have the same date prefix (`20260309`), confirming they were created in the same development session. Every future developer reading the migration log will wonder why `ended_at` was a late addition — it wasn't.

## Proposed Solutions

### Option A — Delete both, create single canonical migration (Recommended, pre-production only)

1. Roll back both migrations: `bin/rails db:rollback STEP=2`
2. Delete both migration files
3. Create a single migration with all columns:
```ruby
class CreateHealthEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :health_events do |t|
      t.references :user, null: false, foreign_key: true
      t.string     :event_type, null: false
      t.datetime   :recorded_at, null: false
      t.datetime   :ended_at
      t.timestamps
    end
    add_index :health_events, [ :user_id, :recorded_at ]
  end
end
```
4. Run `bin/rails db:migrate`

**Pros:** Clean migration history. No transient schema states.
**Effort:** Small
**Risk:** Low (pre-production — no shared environment with this migration run)

### Option B — Leave as-is
If the migrations have been run in any shared environment (staging, CI with persistent DB), leave them. The runtime behaviour is identical.

**Effort:** Zero
**Risk:** Technical debt accumulation

## Recommended Action

Option A if this is pre-production and no shared environment has run the migrations. Option B otherwise.

## Technical Details

**Verify current migration status:**
```bash
bin/rails db:migrate:status | grep health_event
```

## Acceptance Criteria

- [ ] Only one migration file for `health_events` exists in `db/migrate/`
- [ ] The single migration includes `ended_at` in the `create_table` block
- [ ] `db/schema.rb` shows `health_events` table with all columns including `ended_at`
- [ ] `bin/rails db:migrate:status` shows the single migration as `up`
- [ ] `bin/rails test` passes

## Work Log

- 2026-03-09: Identified by kieran-rails-reviewer and architecture-strategist during `ce:review` of Phase 15.
