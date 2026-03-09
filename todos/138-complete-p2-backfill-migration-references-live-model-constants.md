---
status: pending
priority: p2
issue_id: "138"
tags: [code-review, migrations, data-integrity]
dependencies: []
---

# Backfill Migration References Live Model Constants — Fragile for Future Re-runs

## Problem Statement

`20260308130000_backfill_nil_zone_peak_flow_readings.rb` references `PeakFlowReading::GREEN_ZONE_THRESHOLD`, `PeakFlowReading::YELLOW_ZONE_THRESHOLD`, and `PeakFlowReading.zones` at migration runtime. If these constants change in the future, re-running this migration from scratch (e.g., `db:migrate:redo`, fresh database setup) will classify readings with the new thresholds, silently corrupting historical data. This is a known Rails anti-pattern for data migrations.

Flagged by: data-migration-expert (critical), pattern-recognition-specialist.

## Findings

**File:** `db/migrate/20260308130000_backfill_nil_zone_peak_flow_readings.rb`, lines 17–21

```ruby
zone = if pct >= PeakFlowReading::GREEN_ZONE_THRESHOLD then "green"
       elsif pct >= PeakFlowReading::YELLOW_ZONE_THRESHOLD then "yellow"
       else "red"
       end
reading.update_column(:zone, PeakFlowReading.zones[zone])
```

Current values confirmed: `GREEN_ZONE_THRESHOLD = 80`, `YELLOW_ZONE_THRESHOLD = 50`, `zones = { "green" => 0, "yellow" => 1, "red" => 2 }`.

## Proposed Solution

Inline the constants as they existed when the migration was written:

```ruby
# Constants as of 2026-03-08 when this migration was written.
# Do NOT reference PeakFlowReading constants here — inline values are required
# so re-running this migration on a fresh DB produces consistent results.
green_zone_threshold  = 80
yellow_zone_threshold = 50
zone_map = { "green" => 0, "yellow" => 1, "red" => 2 }.freeze

zone = if pct >= green_zone_threshold then "green"
       elsif pct >= yellow_zone_threshold then "yellow"
       else "red"
       end
reading.update_column(:zone, zone_map[zone])
```

Also update the `DATE()` query in the same migration (see todo #134).

## Acceptance Criteria

- [ ] Migration uses inline integer literals (80, 50) instead of model constants
- [ ] Migration uses inline zone hash instead of `PeakFlowReading.zones`
- [ ] Migration runs correctly on a fresh database
- [ ] All zone backfill behavior is unchanged

## Work Log

- 2026-03-08: Identified by data-migration-expert and pattern-recognition-specialist
