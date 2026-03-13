---
status: pending
priority: p2
issue_id: "345"
tags: [code-review, testing, caching, rails]
dependencies: []
---

# MedicationDashboardCacheTest setup has dead code and inconsistent teardown pattern

## Problem Statement

`MedicationDashboardCacheTest` (added in the Phase 22 review fix) has two issues:

1. **Dead code in setup**: `Rails.cache.clear` is called before `Rails.cache = MemoryStore.new` — clearing the store that is about to be replaced is a no-op. Additionally, `ActiveSupport::Cache::NullStore` is referenced as a bare expression that pre-loads the constant but does nothing (no assignment, no call).

2. **Inconsistent teardown**: The test saves `@original_cache` in setup and restores it in teardown. The other four cache test classes (`DoseLogDashboardCacheTest`, `HealthEventDashboardCacheTest`, `NotificationBadgeCacheTest`, `BadgeCacheTest`) all hardcode `Rails.cache = ActiveSupport::Cache::NullStore.new` in teardown. The save/restore approach is functionally different (restores whatever the cache was before, instead of resetting to NullStore) and inconsistent with the established pattern.

## Findings

- `test/models/medication_test.rb:437-441` — setup:
  ```ruby
  Rails.cache.clear                          # dead — replaced next line
  ActiveSupport::Cache::NullStore            # dead — no-op constant reference
  @original_cache = Rails.cache             # before swap — saves production cache
  Rails.cache = ActiveSupport::Cache::MemoryStore.new
  ```
- `test/models/medication_test.rb:444-446` — teardown restores `@original_cache` instead of setting NullStore

## Proposed Solutions

### Option A: Align with the established pattern (Recommended)
```ruby
setup do
  @user = users(:verified_user)
  Rails.cache = ActiveSupport::Cache::MemoryStore.new
end

teardown do
  Rails.cache.clear
  Rails.cache = ActiveSupport::Cache::NullStore.new
  Medication.where(name: "Cache Test Med").delete_all
end
```
- **Pros:** Consistent with all other cache test classes
- **Cons:** None
- **Effort:** Small
- **Risk:** Low

## Recommended Action

Option A. Remove dead code, align teardown.

## Technical Details

**Affected files:**
- `test/models/medication_test.rb` — `MedicationDashboardCacheTest` class

## Acceptance Criteria

- [ ] `Rails.cache.clear` before swap removed
- [ ] `ActiveSupport::Cache::NullStore` bare constant reference removed
- [ ] `@original_cache` save/restore removed
- [ ] Teardown uses `Rails.cache.clear` + `Rails.cache = NullStore.new` pattern
- [ ] All 519 tests pass

## Work Log

- 2026-03-13: Identified in Phase 22 code review (pattern-recognition-specialist, code-simplicity-reviewer)
