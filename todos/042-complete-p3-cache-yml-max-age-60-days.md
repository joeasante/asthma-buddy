---
status: complete
priority: p3
issue_id: "042"
tags: [code-review, performance, health-data, caching]
dependencies: []
---

# `cache.yml` `max_age: 60.days` Too Long for Health Data — Risk of Stale Results

## Problem Statement

`config/cache.yml` enables `max_age: <%= 60.days.to_i %>` for all environments. This means any entry in Solid Cache can survive up to 60 days before eviction. For a health-tracking application, 60-day-old cached computations (symptom summaries, aggregates, trend data) could be served as current to users. Per-entry TTLs should be set explicitly at call sites, not as a global ceiling this long.

## Findings

**Flagged by:** performance-oracle (P2 — correctness risk)

**Location:** `config/cache.yml`, line 4

```yaml
max_age: <%= 60.days.to_i %>
```

**Current risk is latent:** No `cache do` blocks or `Rails.cache.fetch` calls exist in current controllers or views. The 60-day window only becomes harmful when explicit caching is added. However, that harm will be silent — a developer adding `Rails.cache.fetch("user_#{id}_stats") { ... }` without an `expires_in:` will get 60-day staleness by default.

**Health data context:** For a HIPAA-relevant app, serving a user's symptom statistics from 2 months ago as if they're current is a meaningful correctness failure.

## Proposed Solutions

### Solution A: Reduce `max_age` to 7 days (Recommended)
```yaml
max_age: <%= 7.days.to_i %>
```
- **Pros:** Still gives Solid Cache room to retain warm entries across a weekend. Prevents 60-day staleness window. Per-entry TTLs should still be set explicitly.
- **Cons:** None meaningful for this app.
- **Effort:** Tiny
- **Risk:** None (more aggressive eviction, not less)

### Solution B: Remove `max_age` (use Solid Cache's default)
Let Solid Cache manage eviction via `max_size` only (LRU eviction).
- **Pros:** Avoids implicit TTL entirely.
- **Cons:** Stale health data could persist indefinitely if cache size is never exceeded.
- **Effort:** Tiny
- **Risk:** Low-Medium for health data

## Recommended Action

Solution A. Additionally: when adding caching in the future, always set explicit `expires_in:` at the call site:
```ruby
Rails.cache.fetch("user_#{id}_symptom_summary", expires_in: 1.hour) { ... }
```

## Technical Details

- **File:** `config/cache.yml`, line 4
- **Note:** `max_age` is a Solid Cache eviction pressure setting, not a per-entry TTL. Both operate independently.

## Acceptance Criteria

- [ ] `cache.yml` `max_age` reduced to 7 days or less
- [ ] Comment in `cache.yml` explains the health-data rationale for the chosen value
- [ ] Any future `Rails.cache.fetch` calls include explicit `expires_in:` for health data

## Work Log

- 2026-03-07: Created from second-pass code review. Flagged by performance-oracle as P2 correctness risk.
