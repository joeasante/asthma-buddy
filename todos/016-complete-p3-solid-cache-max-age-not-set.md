---
status: pending
priority: p3
issue_id: "016"
tags: [code-review, performance, caching, solid-cache]
dependencies: []
---

# Solid Cache `max_age` Not Set — Stale Health Data Can Persist Indefinitely

## Problem Statement

`config/cache.yml` configures Solid Cache with `max_size: 256MB` but `max_age` is commented out. Without a maximum age, cached entries are only evicted when the 256MB size limit is reached (LRU). For health data (symptom averages, peak flow trends), stale cached values can persist indefinitely. Once Phase 3+ caches computed statistics, a user's dashboard could display outdated data forever without a cache expiry strategy.

## Findings

**Flagged by:** performance-oracle

**Location:** `config/cache.yml`

```yaml
# max_age: <%= 1.week / 1.second %>
```

## Proposed Solutions

### Option A — Enable `max_age` with health-appropriate default
```yaml
store_options:
  max_age: <%= 60.days.to_i %>
  max_size: <%= 256.megabytes %>
  namespace: <%= Rails.env %>
```

**Effort:** Trivial
**Risk:** None — entries evicted after 60 days OR when size limit hit (whichever comes first)

## Recommended Action

Uncomment and set `max_age` before Phase 3 adds cacheable health data queries.

## Technical Details

**Acceptance Criteria:**
- [ ] `max_age` set to a value appropriate for health data (60 days suggested)
- [ ] Old cache entries are evicted by time, not only by size

## Work Log

- 2026-03-06: Identified by performance-oracle.
