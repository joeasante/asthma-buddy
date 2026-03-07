---
status: pending
priority: p2
issue_id: "066"
tags: [code-review, rails, performance, architecture]
dependencies: []
---

# DB Queries in `create.turbo_stream.erb` + Duplicate `personal_best_at_reading_time` Query on Save

## Problem Statement

Two related performance and architecture issues that should be fixed together:

1. **`create.turbo_stream.erb` runs a database query directly in the view** — `PersonalBestRecord.current_for(Current.user).present?` is called from the Turbo Stream template. The controller success path never assigns `@has_personal_best`, forcing the view to query itself. Queries in views bypass any future caching layer and are a maintenance hazard.

2. **`personal_best_at_reading_time` is called twice on every successful save** — once during `before_save :assign_zone` and a second time from `zone_flash_message` in the controller. The result is fetched twice for no benefit.

Combined effect: every successful create action fires **5 queries** (user lookup, pb lookup for zone, INSERT, pb lookup for flash, pb lookup in view). Fixes here drop it to **3 queries** — a 40% reduction.

## Findings

**Flagged by:** performance-oracle, kieran-rails-reviewer, architecture-strategist, pattern-recognition-specialist

**Issue 1 — view query:**
```erb
<%# app/views/peak_flow_readings/create.turbo_stream.erb:7 %>
has_personal_best: PersonalBestRecord.current_for(Current.user).present?
```
Controller success path (line 18-23) never assigns `@has_personal_best`. The failure path (line 23) does. This inconsistency forces the view to compensate.

**Issue 2 — duplicate query:**
```ruby
# Query 1: before_save -> assign_zone -> compute_zone -> personal_best_at_reading_time (DB)
# ...save...
# Query 2: zone_flash_message -> personal_best_at_reading_time (same query, again)
def zone_flash_message(reading)
  pb = reading.personal_best_at_reading_time  # redundant round-trip
```

## Proposed Solutions

### Option A: Fix both with two targeted changes (Recommended)

**Fix 1 — assign `@has_personal_best` in create success path:**

```ruby
# app/controllers/peak_flow_readings_controller.rb
if @peak_flow_reading.save
  @flash_message = zone_flash_message(@peak_flow_reading)
  @has_personal_best = PersonalBestRecord.current_for(Current.user).present?  # ADD
  respond_to do |format|
    format.turbo_stream
    format.html { redirect_to new_peak_flow_reading_path, notice: @flash_message }
  end
```

Then update `create.turbo_stream.erb` to reference the ivar:
```erb
has_personal_best: @has_personal_best
```

**Fix 2 — memoize `personal_best_at_reading_time`:**

```ruby
# app/models/peak_flow_reading.rb
def personal_best_at_reading_time
  @personal_best_at_reading_time ||= user.personal_best_records
      .where("recorded_at <= ?", recorded_at)
      .order(recorded_at: :desc)
      .pick(:value)
end
```

The `@` memoization is scoped to the object instance (one request). `compute_zone` and `zone_flash_message` both call it; with memoization the DB is hit only once.

**Pros:** Minimal change, eliminates 2 of 5 queries, keeps view passive, consistent with failure path
**Cons:** None
**Effort:** Small (4 lines across 3 files)
**Risk:** Zero

### Option B: Move Turbo Stream logic inline to controller, delete view file

```ruby
# Controller success path
format.turbo_stream do
  render turbo_stream: [
    turbo_stream.replace("peak_flow_reading_form",
      partial: "form",
      locals: { peak_flow_reading: Current.user.peak_flow_readings.new(...), has_personal_best: @has_personal_best }
    ),
    turbo_stream.prepend("main-content",
      html: "<p role='status' class='flash flash--notice'>#{ERB::Util.html_escape(@flash_message)}</p>"
    )
  ]
end
```

Then delete `create.turbo_stream.erb`.

**Pros:** Eliminates the view file entirely; all logic in controller
**Cons:** Inline HTML in controller is worse than a view file; symptom_logs also uses a turbo_stream.erb, so this would diverge from that pattern
**Effort:** Medium
**Risk:** Low

## Recommended Action

Option A — minimal change, maximum impact.

## Technical Details

**Affected files:**
- `app/controllers/peak_flow_readings_controller.rb` (+1 line)
- `app/views/peak_flow_readings/create.turbo_stream.erb` (change `PersonalBestRecord.current_for(...)` to `@has_personal_best`)
- `app/models/peak_flow_reading.rb` (memoize with `||=`)

## Acceptance Criteria

- [ ] `@has_personal_best` assigned in the create success path
- [ ] `create.turbo_stream.erb` references `@has_personal_best` instead of querying
- [ ] `personal_best_at_reading_time` memoized with `@personal_best_at_reading_time ||=`
- [ ] Query count on successful create drops from 5 to 3 (verifiable with `ActiveRecord::QueryCounter` or query log)
- [ ] All 142 existing tests still pass

## Work Log

- 2026-03-07: Identified by performance-oracle, kieran-rails-reviewer, architecture-strategist during Phase 6 code review

## Resources

- `app/controllers/peak_flow_readings_controller.rb`
- `app/views/peak_flow_readings/create.turbo_stream.erb`
- `app/models/peak_flow_reading.rb`
