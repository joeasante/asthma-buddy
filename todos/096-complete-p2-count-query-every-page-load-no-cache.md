---
status: pending
priority: p2
issue_id: "096"
tags: [code-review, performance, rails, peak-flow, solid-cache]
dependencies: []
---

# COUNT query fires on every page load for pagination — no Solid Cache

## Problem Statement

`@total_pages = [ (base_relation.count.to_f / 25).ceil, 1 ].max` issues a `SELECT COUNT(*)` on every request, including every Turbo Frame filter chip click and pagination navigation. The composite index `(user_id, recorded_at)` makes this fast at current scale, but Solid Cache is already in the stack and makes caching this trivially free.

## Findings

**Flagged by:** performance-oracle (P1), architecture-strategist (context)

**Location:** `app/controllers/peak_flow_readings_controller.rb:53`

```ruby
@total_pages = [ (base_relation.count.to_f / 25).ceil, 1 ].max
```

**Scalability estimate:**
- < 500 rows/user: sub-ms, index-only scan — fine
- 1,000–3,000 rows/user: still fast, but every filter click pays the cost
- 10,000+ rows: COUNT index scan becomes measurable; caching is meaningful

## Proposed Solutions

### Option A: Cache with Solid Cache, 1-minute TTL (Recommended)

```ruby
cache_key = "pfr_count/#{Current.user.id}/#{@active_preset}/#{@start_date}/#{@end_date}"
total_count = Rails.cache.fetch(cache_key, expires_in: 1.minute) { base_relation.count }
@total_pages = [ (total_count.to_f / 25).ceil, 1 ].max
```

1-minute TTL means a reading created mid-session appears on the next natural page refresh.

- **Pros:** Zero infrastructure cost (Solid Cache already running); eliminates repeated COUNT; trivial code change
- **Effort:** Small
- **Risk:** Stale count for up to 60 seconds after create/destroy — acceptable given design

### Option B: Move pagination to model (Full refactor)

Mirror `SymptomLog.paginate` — encapsulate COUNT + OFFSET in a model method. Benefits include testability and reuse, but is larger scope.

- **Effort:** Medium
- **Risk:** Low

## Recommended Action

Option A now; Option B as part of the broader model-layer refactor (see todo 099).

## Technical Details

- **Affected files:** `app/controllers/peak_flow_readings_controller.rb`

## Acceptance Criteria

- [ ] `SELECT COUNT(*)` does not fire on every filter/page navigation (verify via `Rails.logger` or `EXPLAIN`)
- [ ] Cache is keyed on user_id + preset + date params (different users don't share counts)
- [ ] Cache invalidated within 1 minute after a create or destroy

## Work Log

- 2026-03-07: Identified during Phase 7 code review
