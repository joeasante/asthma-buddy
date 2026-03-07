---
status: pending
priority: p2
issue_id: "077"
tags: [code-review, performance, rails, duplication]
dependencies: []
---

# `@has_personal_best` Assigned Identically in Three Places

## Problem Statement

`PersonalBestRecord.current_for(Current.user).present?` is assigned to `@has_personal_best` in three separate locations: `new` action, `create` success branch, and `create` failure branch. Each fires a DB query. A `before_action` would consolidate this to one canonical assignment, one query per request, following the pattern already established by `SymptomLogsController`.

## Findings

**Flagged by:** performance-oracle (P1-A), kieran-rails-reviewer (P2), pattern-recognition-specialist (P1-1, P2-4), architecture-strategist (P3), code-simplicity-reviewer

**Locations:**
- `app/controllers/peak_flow_readings_controller.rb:10` (new action)
- `app/controllers/peak_flow_readings_controller.rb:18` (create success)
- `app/controllers/peak_flow_readings_controller.rb:25` (create failure)

On the success path, the query on line 18 is redundant because `@peak_flow_reading.personal_best_at_reading_time` was already memoized during `before_save`. The success-path assignment can read from the ivar instead of hitting the DB again:

```ruby
# Success path optimization — reads memoized ivar, zero extra queries:
@has_personal_best = @peak_flow_reading.personal_best_at_reading_time.present?
```

## Proposed Solutions

### Option A: `before_action` + success-path ivar read (Recommended)
**Effort:** Small | **Risk:** Low

```ruby
before_action :set_has_personal_best, only: %i[new create]

def create
  @peak_flow_reading = Current.user.peak_flow_readings.new(peak_flow_reading_params)

  if @peak_flow_reading.save
    @flash_message = zone_flash_message(@peak_flow_reading)
    # Override with memoized value from the just-saved record — no extra query:
    @has_personal_best = @peak_flow_reading.personal_best_at_reading_time.present?
    respond_to { ... }
  else
    respond_to { ... }  # @has_personal_best already set by before_action
  end
end

private

def set_has_personal_best
  @has_personal_best = PersonalBestRecord.current_for(Current.user).present?
end
```

### Option B: Single assignment before the if/else
**Effort:** Tiny | **Risk:** Low

```ruby
def create
  @peak_flow_reading = Current.user.peak_flow_readings.new(peak_flow_reading_params)
  @has_personal_best = PersonalBestRecord.current_for(Current.user).present?

  if @peak_flow_reading.save
    @flash_message = zone_flash_message(@peak_flow_reading)
    respond_to { ... }
  else
    respond_to { ... }
  end
end
```

Removes duplicate assignments but still fires the query before attempting save. Does not extract to before_action, so `new` still has its own copy.

## Recommended Action

Option A — before_action for `new` and `create`, with success-path override from the memoized record. Eliminates all duplication, eliminates one extra DB query on the success path, and matches the Rails convention of using `before_action` for shared setup.

## Technical Details

**Affected files:**
- `app/controllers/peak_flow_readings_controller.rb`

## Acceptance Criteria

- [ ] `@has_personal_best` set exactly once per action (via before_action)
- [ ] No separate assignment in success or failure branch of `create`
- [ ] `bin/rails test` passes with 0 failures

## Work Log

- 2026-03-07: Identified by performance-oracle, kieran-rails-reviewer, pattern-recognition-specialist in Phase 6 code review
