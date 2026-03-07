---
status: pending
priority: p2
issue_id: "023"
tags: [code-review, performance, sqlite, memory, deployment]
dependencies: []
---

# SQLite PRAGMAs Uniform Across All 4 DBs — OOM Risk at WEB_CONCURRENCY > 1

## Problem Statement

`config/initializers/database_wal.rb` applies the same `cache_size=-32000` (32MB) and `mmap_size=134217728` (128MB) to all four SQLite databases (primary, cache, queue, cable). Since `SQLite3Adapter.prepend` is global, every connection to every database carries this memory budget. At WEB_CONCURRENCY=2 with 5-connection pools, page cache alone reaches ~1.28GB — enough to OOM-kill a 1-2GB Kamal host. The queue/cable/cache databases have fundamentally different access patterns and don't benefit from large page caches.

## Findings

**Flagged by:** performance-oracle (P1 finding)

**Location:** `config/initializers/database_wal.rb`

```ruby
execute("PRAGMA cache_size=-32000;")   # 32MB per connection — applied to ALL 4 databases
execute("PRAGMA mmap_size=134217728;") # 128MB per connection — applied to ALL 4 databases
```

**Worst-case calculation (WEB_CONCURRENCY=2, 5-connection pool):**
```
2 workers × 4 DBs × 5 conns × 32 MB cache_size = 1,280 MB
2 workers × 4 DBs × 128 MB mmap_size           = 1,024 MB (virtual → can become RSS)
Rails baseline × 2                              ≈  300 MB
Total                                           ≈ 2,580 MB  ← OOM on 2GB host
```

**Current state (WEB_CONCURRENCY=1) is safe:**
```
1 worker × 4 DBs × 3 active conns × 32 MB = 384 MB cache
1 worker × 4 DBs × 128 MB mmap            = 512 MB virtual
Rails baseline                             ≈ 150 MB
Total                                      ≈ 650 MB  ← fine
```

The risk is latent but triggered the moment someone sets `WEB_CONCURRENCY=2` in `deploy.yml`.

## Proposed Solutions

### Solution A: Differentiate PRAGMA values by database role (Recommended)

```ruby
def configure_connection
  super
  # ... WAL verification, busy_timeout, synchronous, temp_store unchanged ...

  db_path = @config[:database].to_s

  if db_path =~ /_(cache|queue|cable)/
    # High-churn, small-row workloads — minimal cache sufficient
    execute("PRAGMA cache_size=-4000;")    # 4MB
    execute("PRAGMA mmap_size=33554432;")  # 32MB
  else
    # Primary health data DB — range scans benefit from larger cache
    execute("PRAGMA cache_size=-16000;")   # 16MB (halved from current)
    execute("PRAGMA mmap_size=134217728;") # 128MB
  end
end
```

**Memory at WEB_CONCURRENCY=2 with fix:**
```
Primary: 2 × 5 × 16MB  = 160MB
Others:  2 × 3 × 5 × 4MB = 120MB
Rails:   ~300MB
Total:   ~580MB  ← safe on 1GB host
```

- **Effort:** Small
- **Risk:** None (smaller cache on ancillary DBs has no visible performance impact for queue/cable patterns)

### Solution B: Add inline documentation and hard-cap `WEB_CONCURRENCY` in deploy.yml

Add a comment in `database_wal.rb` explaining the memory budget and add to `config/deploy.yml`:
```yaml
env:
  clear:
    WEB_CONCURRENCY: "1"  # See database_wal.rb memory budget notes before increasing
```
- **Pros:** Prevents accidental OOM without changing PRAGMA values.
- **Cons:** Doesn't actually fix the underlying issue — just prevents the scaling path.
- **Effort:** Small
- **Risk:** Low (limits future scale)

## Recommended Action

Solution A. Differentiate by database role — the primary database is the one that benefits from large caches (health data dashboards with range scans), while queue/cable/cache are append-heavy with tiny rows.

## Technical Details

- **Affected file:** `config/initializers/database_wal.rb`
- **Config to reference:** `@config[:database]` inside `configure_connection` gives the db file path
- **Related:** `config/deploy.yml` — `WEB_CONCURRENCY` is currently commented out (safe), but should document the memory constraint

## Acceptance Criteria

- [ ] Primary database gets larger cache; queue/cable/cache get smaller values
- [ ] Memory estimate at WEB_CONCURRENCY=2 is under 1GB total
- [ ] All `rails test` pass
- [ ] WAL mode still activates correctly on all 4 databases
- [ ] Deploy.yml comment explains the memory budget

## Work Log

- 2026-03-06: Identified by performance-oracle during /ce:review of foundation phase changes
