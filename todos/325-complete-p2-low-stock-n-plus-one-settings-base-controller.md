---
status: complete
priority: p2
issue_id: "325"
tags: [code-review, performance, n-plus-one, medications, settings]
dependencies: []
---

# N+1 on `low_stock?` in `Settings::BaseController#set_header_eyebrow_vars`

## Problem Statement

`app/controllers/settings/base_controller.rb#set_header_eyebrow_vars` loads medications for the eyebrow stats and calls `low_stock?` on each one. `low_stock?` calls `remaining_doses` which calls `dose_logs.sum(:puffs)` — a separate SQL query per medication. With N medications, this fires N+1 queries on every settings page load. A user with 5 medications triggers 6 queries just for the page header stats.

## Findings

**Flagged by:** kieran-rails-reviewer (rated HIGH)

```ruby
# app/controllers/settings/base_controller.rb:6-11
def set_header_eyebrow_vars
  @medications = Current.user.medications  # 1 query
  @low_stock_count = @medications.count(&:low_stock?)  # N queries — one per medication
end
```

`low_stock?` → `remaining_doses` → `dose_logs.sum(:puffs)` fires SQL per medication.

Fix: eager-load dose_logs:
```ruby
@medications = Current.user.medications.includes(:dose_logs)
```

With `includes(:dose_logs)`, `dose_logs.sum(:puffs)` should use the in-memory collection (once todo 322's `loaded?` guard is applied).

## Proposed Solutions

### Option A: `includes(:dose_logs)` (Recommended)
```ruby
@medications = Current.user.medications.includes(:dose_logs)
```

Combined with todo 322's `loaded?` guard in `remaining_doses`, this reduces to 2 queries total.

**Pros:** Standard Rails eager loading; clean
**Cons:** Loads all dose log records into memory (acceptable — per-user, bounded)
**Effort:** Small (1 line)
**Risk:** Low

### Option B: Counter cache on `medications` table
Add a `dose_logs_count` counter cache and use that instead of summing.

**Pros:** O(1) per medication
**Cons:** Counter cache counts ALL logs, not just post-refill — same bug as todo 322
**Effort:** Medium
**Risk:** Medium

### Recommended Action

Option A, dependent on todo 322 being fixed first (or simultaneously).

## Technical Details

- **File:** `app/controllers/settings/base_controller.rb`
- **Dependency:** todo 322 (remaining_doses loaded? guard)

## Acceptance Criteria

- [ ] `set_header_eyebrow_vars` uses `includes(:dose_logs)`
- [ ] Settings pages fire ≤ 3 queries for the header eyebrow (medications + dose_logs + 1)
- [ ] No N+1 warnings in logs for settings pages

## Work Log

- 2026-03-12: Created from Milestone 2 code review — kieran-rails-reviewer HIGH finding
