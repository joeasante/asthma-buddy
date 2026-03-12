---
status: complete
priority: p2
issue_id: "278"
tags: [code-review, database, migration, timezone, security, peak-flow]
dependencies: ["274"]
---

# SQLite `DATE(recorded_at)` in unique index uses UTC — silent coupling with Rails timezone

## Problem Statement

The new unique index uses `DATE(recorded_at)` as an expression key. SQLite always evaluates `DATE()` in UTC, regardless of any timezone configuration. The Ruby-level `one_session_per_day` validation uses `recorded_at.to_date`, which respects the Rails process timezone (`Time.zone`).

Currently `config/application.rb` does not set `config.time_zone`, so Rails defaults to UTC and the two layers are aligned. **This is a silent coupling.** If anyone ever adds `config.time_zone = "London"` (UTC+1) or `"Sydney"` (UTC+10/11), the DB index and the Ruby validation would compute different "calendar days" for readings near midnight, producing:
- False positives: two readings from different local days blocked as duplicates
- False negatives: two readings from the same local day allowed through

In a medical-adjacent app, incorrect duplicate detection could prevent legitimate health data from being recorded.

## Findings

- **Migration:** `db/migrate/20260311200000_add_unique_session_index_to_peak_flow_readings.rb:8` — `DATE(recorded_at)` in SQLite
- **Model:** `app/models/peak_flow_reading.rb:94` — `recorded_at.to_date` in Ruby
- **Agent:** data-migration-expert, security-sentinel
- The current state is safe (UTC default). The risk is entirely future-change triggered.

## Proposed Solutions

### Option A — Document the coupling in two places (Immediate, Required)

1. Add a comment to the migration:
   ```ruby
   # NOTE: DATE(recorded_at) evaluates in UTC. The Rails-level validation in
   # one_session_per_day also uses UTC (Rails default timezone). If config.time_zone
   # is ever set to a non-UTC value, both this index and the Ruby validation must be
   # audited together — they will disagree about what "calendar day" means.
   ```

2. Add a comment to `config/application.rb`:
   ```ruby
   # IMPORTANT: peak_flow_readings has a unique index on DATE(recorded_at) evaluated
   # in UTC. Changing time_zone here will break duplicate session detection for users
   # near midnight in their local timezone. See todo 278.
   ```

**Effort:** Trivial
**Risk:** None

### Option B — Add a persisted `recorded_on` date column (Long-term fix)

Add a `recorded_on:date` column that stores the user's local calendar date at time of entry. Index on `(user_id, time_of_day, recorded_on)` instead of the expression index. This permanently decouples the constraint from timezone concerns.

**Pros:** Timezone-safe. Explicit. Queryable.
**Cons:** Requires a migration. More complex to backfill.
**Effort:** Medium
**Risk:** Low (additive migration)

## Recommended Action

Option A immediately (comments). Option B as a follow-on improvement if timezone support is ever needed.

## Technical Details

- **Affected files:**
  - `db/migrate/20260311200000_add_unique_session_index_to_peak_flow_readings.rb`
  - `config/application.rb`

## Acceptance Criteria

- [x] Migration file has UTC coupling comment
- [x] `config/application.rb` has warning comment about timezone and peak flow index
- [x] No functional change

## Work Log

- 2026-03-11: Identified by data-migration-expert and security-sentinel during code review of dev branch
- 2026-03-11: Fixed — added UTC coupling comments to both migration and config/application.rb
