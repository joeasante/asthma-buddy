---
status: pending
priority: p2
issue_id: "082"
tags: [code-review, rails, data-integrity, future-proofing]
dependencies: []
---

# `personal_best_at_reading_time` Memoization Breaks if `recorded_at` Is Mutated

## Problem Statement

`PeakFlowReading#personal_best_at_reading_time` is memoized with `@personal_best_at_reading_time ||= ...`. The memoized value is keyed to the object instance, not to the value of `recorded_at`. If `recorded_at` is mutated after the first call (e.g. on a future `edit`/`update` action), the cached personal best would be stale — computed against the old `recorded_at`. `before_save` would then persist a zone based on the wrong personal best.

This is a loaded trap: the code is correct today (only `new` + `create` exist, `recorded_at` is set from params before any method runs), but will silently corrupt zone data the moment an edit action is added.

## Findings

**Flagged by:** architecture-strategist (P1)

**Current** (`app/models/peak_flow_reading.rb:17–22`):
```ruby
def personal_best_at_reading_time
  @personal_best_at_reading_time ||= user.personal_best_records
      .where("recorded_at <= ?", recorded_at)
      .order(recorded_at: :desc)
      .pick(:value)
end
```

**Failure scenario:**
```ruby
reading = PeakFlowReading.find(1)
reading.personal_best_at_reading_time  # → 520 (memoized for original recorded_at)
reading.recorded_at = 2.years.ago       # mutated
reading.save                            # before_save → compute_zone → personal_best_at_reading_time
                                        # → returns memoized 520 ← WRONG (should be nil for 2 years ago)
```

## Proposed Solutions

### Option A: Remove memoization, add explanatory comment (Recommended)
**Effort:** Tiny | **Risk:** Very Low

```ruby
def personal_best_at_reading_time
  # Not memoized — recorded_at can change on update (future edit action), which
  # would make a memoized result stale for before_save recomputation.
  user.personal_best_records
      .where("recorded_at <= ?", recorded_at)
      .order(recorded_at: :desc)
      .pick(:value)
end
```

Two queries per save (one in `compute_zone` via `before_save`, one in `zone_percentage` via `zone_flash_message`) is negligible at this scale. The memoization was preventing a third query in `peak_flow_reading_json`, but that can be addressed by reading `reading.zone_percentage` which is already computed, or by caching only within an explicit scope.

### Option B: Key memoization on `recorded_at` value
**Effort:** Small | **Risk:** Low

```ruby
def personal_best_at_reading_time
  return @personal_best_cache[:value] if @personal_best_cache&.fetch(:recorded_at) == recorded_at

  @personal_best_cache = {
    recorded_at: recorded_at,
    value: user.personal_best_records
               .where("recorded_at <= ?", recorded_at)
               .order(recorded_at: :desc)
               .pick(:value)
  }
  @personal_best_cache[:value]
end
```

Safe across mutations but more complex. Premature optimization unless there's a real performance concern.

### Option C: Persist `zone_percentage` (longer term)
**Effort:** Medium | **Risk:** Low

Store `zone_percentage` as an integer column computed once in `before_save`. Eliminates the `personal_best_at_reading_time` call from `zone_percentage` entirely, making the memoization risk moot. See todo 086.

## Recommended Action

Option A — remove memoization with a comment. Two queries per save is not a performance problem for this app. The comment makes the decision explicit so future developers adding an edit action understand why it was removed.

## Technical Details

**Affected files:**
- `app/models/peak_flow_reading.rb`

## Acceptance Criteria

- [ ] `personal_best_at_reading_time` has no instance variable memoization
- [ ] Comment explains why memoization was intentionally avoided
- [ ] `bin/rails test` passes with 0 failures

## Work Log

- 2026-03-07: Identified by architecture-strategist in Phase 6 code review
