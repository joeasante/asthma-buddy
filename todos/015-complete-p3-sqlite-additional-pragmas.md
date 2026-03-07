---
status: pending
priority: p3
issue_id: "015"
tags: [code-review, performance, sqlite, database]
dependencies: ["004"]
---

# Additional SQLite Performance PRAGMAs Missing

## Problem Statement

Beyond `busy_timeout` (addressed in todo #004), several SQLite PRAGMAs recommended for production health-app performance are not configured. These are low-priority now but will matter as the dataset grows with symptom logs and peak flow readings.

## Findings

**Flagged by:** performance-oracle

| PRAGMA | Recommended Value | Benefit |
|--------|-----------------|---------|
| `cache_size` | `-32000` (32MB) | Reduces disk I/O for read-heavy dashboards (default is 2MB) |
| `mmap_size` | `134217728` (128MB) | Memory-mapped I/O reduces read latency for repeated scans |
| `temp_store` | `MEMORY` | Keeps temp tables/indexes in memory, avoids temp files |
| `journal_size_limit` | `67108864` (64MB) | Caps WAL file growth |

These go in `configure_connection` alongside `busy_timeout` and `synchronous=NORMAL`.

## Proposed Solutions

### Option A — Add all to WAL initializer
```ruby
def configure_connection
  super
  execute("PRAGMA journal_mode=WAL;")
  execute("PRAGMA busy_timeout=5000;")
  execute("PRAGMA synchronous=NORMAL;")
  execute("PRAGMA cache_size=-32000;")
  execute("PRAGMA mmap_size=134217728;")
  execute("PRAGMA temp_store=MEMORY;")
  execute("PRAGMA journal_size_limit=67108864;")
end
```

**Effort:** Small
**Risk:** None — all are well-established SQLite production settings

## Recommended Action

Do this after todo #004 (busy_timeout) is resolved and the initializer is settled.

## Technical Details

**Acceptance Criteria:**
- [ ] All 4 PRAGMAs added to connection setup
- [ ] App boots without errors
- [ ] Test suite passes

## Work Log

- 2026-03-06: Identified by performance-oracle. Deferred to P3 — not urgent until data models exist.
