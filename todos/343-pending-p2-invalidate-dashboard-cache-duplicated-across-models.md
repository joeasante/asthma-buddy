---
status: pending
priority: p2
issue_id: "343"
tags: [code-review, architecture, dry, rails, caching]
dependencies: []
---

# invalidate_dashboard_cache private method duplicated verbatim in three models

## Problem Statement

Three models each define an identical private method:

```ruby
def invalidate_dashboard_cache
  Rails.cache.delete(DashboardVariables.dashboard_cache_key(user_id))
end
```

This exists in `DoseLog` (line 35), `HealthEvent` (line 152), and `Medication` (line 112). Additionally, all three models reference `DashboardVariables`, a controller concern, creating an inverted dependency: the model layer depends on the controller layer.

If the cache key format ever changes, or if the invalidation logic needs to be extended (e.g., adding a log entry or secondary invalidation), the change must be made in three places.

## Findings

- `app/models/dose_log.rb:35` — `invalidate_dashboard_cache` method
- `app/models/health_event.rb:152` — identical `invalidate_dashboard_cache` method
- `app/models/medication.rb:112` — identical `invalidate_dashboard_cache` method
- All three reference `DashboardVariables` (a controller concern) directly from the model layer

## Proposed Solutions

### Option A: Extract to a shared model concern (Recommended)

Create `app/models/concerns/dashboard_cache_invalidatable.rb`:
```ruby
module DashboardCacheInvalidatable
  extend ActiveSupport::Concern

  DASHBOARD_CACHE_KEY = ->(user_id, date = Date.current) { "dashboard_vars/#{user_id}/#{date}" }

  private

    def invalidate_dashboard_cache
      Rails.cache.delete(DASHBOARD_CACHE_KEY.call(user_id))
    end
end
```

Include in DoseLog, HealthEvent, Medication. This also resolves the controller-concern dependency.

- **Pros:** Single definition, removes cross-layer dependency, cache key logic lives with the models
- **Cons:** Requires moving `DashboardVariables.dashboard_cache_key` or duplicating the key format
- **Effort:** Small
- **Risk:** Low

### Option B: Move dashboard_cache_key to a neutral shared module

Move the `dashboard_cache_key` class method to a location that both models and controllers can reference (e.g., `app/models/concerns/cache_keys.rb` or a plain module in `app/lib/`).

- **Pros:** Resolves dependency inversion without duplicating key format
- **Cons:** Creates a new shared module that needs to be maintained
- **Effort:** Small
- **Risk:** Low

### Option C: Accept current state

Three identical methods, all referencing a controller concern. Works but violates DRY and layering.
- **Effort:** None
- **Risk:** Low (cosmetic only until the key format changes)

## Recommended Action

Option A or B. Option A is more self-contained.

## Technical Details

**Affected files:**
- `app/models/dose_log.rb`
- `app/models/health_event.rb`
- `app/models/medication.rb`
- `app/controllers/concerns/dashboard_variables.rb` — `dashboard_cache_key` may need to move

## Acceptance Criteria

- [ ] `invalidate_dashboard_cache` defined in exactly one place
- [ ] Models no longer reference `DashboardVariables` (a controller concern)
- [ ] All three models' callbacks still call the correct cache key
- [ ] Tests pass

## Work Log

- 2026-03-13: Identified in Phase 22 code review (pattern-recognition-specialist, architecture-strategist, code-simplicity-reviewer)
