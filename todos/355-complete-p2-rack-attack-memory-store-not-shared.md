---
status: complete
priority: p2
issue_id: 355
tags: [code-review, security, rate-limiting]
dependencies: []
---

## Problem Statement

`Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new` means each Puma worker has independent counters. An attacker gets `5 x num_workers` attempts before throttling. The comment "so throttle counters persist across requests" is misleading.

## Findings

In `config/initializers/rack_attack.rb`, the cache store is set to `ActiveSupport::Cache::MemoryStore.new`. MemoryStore is per-process, so in a multi-worker Puma setup each worker maintains its own independent throttle counters. An attacker can effectively multiply their allowed attempts by the number of workers. The inline comment suggests the store persists counters, which is only true within a single worker process.

## Proposed Solutions

**A) Use `Rails.cache` (Solid Cache / SQLite-backed) in production, MemoryStore in dev/test (Recommended)**
- Pros: Shared across all workers; uses existing infrastructure (Solid Cache); no new dependencies
- Cons: Slightly higher latency than in-memory; need conditional logic per environment

**B) Document the limitation and accept it for single-worker deployments**
- Pros: No code change
- Cons: Breaks if worker count increases; misleading for future developers

**C) Use a file-based cache store**
- Pros: Shared across workers without external dependencies
- Cons: File I/O overhead; cache expiry management; not ideal for high-frequency counters

## Recommended Action



## Technical Details

**Affected files:**
- `config/initializers/rack_attack.rb`

## Acceptance Criteria

- [ ] Production uses a shared cache store for Rack::Attack
- [ ] Rate limiting works correctly across multiple workers
