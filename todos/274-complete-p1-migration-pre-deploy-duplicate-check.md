---
status: complete
priority: p1
issue_id: "274"
tags: [code-review, database, migration, deployment, peak-flow]
dependencies: []
---

# Pre-deploy duplicate check required before migration can run safely

## Problem Statement

`AddUniqueSessionIndexToPeakFlowReadings` will fail with `UNIQUE constraint failed` if the production database contains any rows with the same `(user_id, time_of_day, DATE(recorded_at))` combination. The migration has no dedup step. If duplicates exist (possible if users created them before this validation was added), the migration aborts, Kamal keeps the old container running, but the deploy fails.

This is a **pre-deployment action item** that must be completed before the migration reaches production.

## Findings

- **File:** `db/migrate/20260311200000_add_unique_session_index_to_peak_flow_readings.rb`
- **Agent:** data-migration-expert, deployment-verification-agent
- Migration has already run successfully in development (schema.rb shows the index) — confirming no duplicates existed in dev at the time
- Seeds file is empty — no risk from `db:seed`
- Test fixtures have no duplicate sessions — test suite will pass
- **Production status is unknown** — must be verified before deploy

## Required Pre-Deploy Actions

### Step 1 — Run this query against production before deploying

```bash
kamal app exec --interactive --reuse -- sqlite3 /rails/storage/production.sqlite3
```

```sql
-- THE GO/NO-GO QUERY
SELECT
    user_id,
    time_of_day,
    DATE(recorded_at) AS reading_date,
    COUNT(*)          AS duplicate_count
FROM peak_flow_readings
GROUP BY user_id, time_of_day, DATE(recorded_at)
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;
```

**Expected result: zero rows.** If any rows are returned, DO NOT DEPLOY — resolve duplicates first (see below).

### Step 2 — If duplicates exist, identify them

```sql
SELECT p.id, p.user_id, p.time_of_day, DATE(p.recorded_at) AS reading_date, p.value
FROM peak_flow_readings p
INNER JOIN (
    SELECT user_id, time_of_day, DATE(recorded_at) AS reading_date
    FROM peak_flow_readings
    GROUP BY user_id, time_of_day, DATE(recorded_at)
    HAVING COUNT(*) > 1
) dup ON dup.user_id = p.user_id
      AND dup.time_of_day = p.time_of_day
      AND DATE(p.recorded_at) = dup.reading_date
ORDER BY p.user_id, p.time_of_day, p.recorded_at;
```

Keep the row with the highest `value` (most clinically relevant) and delete the others:
```sql
DELETE FROM peak_flow_readings WHERE id IN (/* IDs to remove */);
```

### Step 3 — Take a pre-deploy backup

```bash
kamal app exec --reuse -- cat /rails/storage/production.sqlite3 \
  > ~/backups/pre_unique_index_$(date +%Y%m%d_%H%M%S).sqlite3
```

## Proposed Solutions

### Option A — Pre-deploy manual check (Required regardless)

Run the GO/NO-GO query. If clean, deploy. This must happen before every deploy of this changeset.

**Effort:** Small (10 minutes)
**Risk:** Zero if query returns clean

### Option B — Add a dedup step to the migration

Add a `before` block that deletes duplicate rows (keeping the highest value):

```ruby
def up
  execute <<~SQL
    DELETE FROM peak_flow_readings
    WHERE id NOT IN (
      SELECT MAX(id) FROM peak_flow_readings
      GROUP BY user_id, time_of_day, DATE(recorded_at)
    );
  SQL
  execute <<~SQL
    CREATE UNIQUE INDEX ...
  SQL
end
```

**Pros:** Self-healing migration.
**Cons:** Silently deletes user health data without consent. Inappropriate for a medical app.
**Risk:** HIGH — never auto-delete health data

## Recommended Action

Option A only. **Never auto-delete health data in a migration.** Do the manual check.

## Acceptance Criteria

- [x] GO/NO-GO query documented in migration as a pre-deploy comment
- [ ] GO/NO-GO query returns zero rows on production before deploying
- [ ] Pre-deploy backup taken and verified non-zero
- [ ] Post-deploy: `SELECT name FROM sqlite_master WHERE type='index' AND name='index_peak_flow_readings_unique_session_per_day'` returns one row
- [ ] Post-deploy: row count matches pre-deploy baseline

## Work Log

- 2026-03-11: Identified by data-migration-expert and deployment-verification-agent during code review of dev branch
- 2026-03-11: Fixed — pre-deploy SQL check comment added to migration file header
