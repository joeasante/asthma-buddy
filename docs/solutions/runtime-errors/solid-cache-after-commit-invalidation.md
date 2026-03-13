---
title: "Solid Cache + after_commit cache invalidation pattern"
slug: solid-cache-after-commit-invalidation
category: runtime-errors
tags: [caching, solid-cache, after_commit, hotwire, dashboard, performance, sqlite]
symptom: "Dashboard shows stale data after medication or dose log changes; cache not invalidated on write"
component: DashboardCacheInvalidatable / DashboardVariables
framework: Rails 8.1.2 / Solid Cache (SQLite)
related: []
---

# Solid Cache + `after_commit` cache invalidation pattern

## Symptom

The dashboard or badge count shows stale data after a record is saved. Refreshing the page still shows old values because the cache entry was not busted on write.

## Context

This app uses **Solid Cache** (SQLite-backed) as the Rails cache store. There is no Redis. Cache keys are namespaced by user and date so each user's data is isolated.

Two caches exist:
- **Dashboard vars** (`dashboard_vars/{user_id}/{date}`) — stores preventer adherence, reliever usage, and active illness. TTL: 5 minutes.
- **Notification badge** (`notifications/badge/{user_id}`) — stores unread notification count. TTL: 5 minutes.

## Pattern established (Phase 22)

### 1. Cache key ownership

Cache keys live as class methods on the **model layer**, not inline strings. This gives a single definition that both models and controllers share without cross-layer coupling.

```ruby
# app/models/concerns/dashboard_cache_invalidatable.rb
def self.dashboard_cache_key(user_id, date = Date.current)
  "dashboard_vars/#{user_id}/#{date}"
end

# app/models/notification.rb
def self.badge_cache_key(user_id)
  "notifications/badge/#{user_id}"
end
```

`DashboardVariables.dashboard_cache_key` (controller concern) delegates to `DashboardCacheInvalidatable.dashboard_cache_key` so all existing callers continue to work.

### 2. Invalidation via `after_commit` (not `after_save`)

Use `after_commit`, never `after_save` or `after_update`. Rails wraps each test in a transaction and rolls it back — `after_save` fires inside the transaction and `after_commit` never fires. This means `after_save` cache writes from tests would silently pass even though production invalidation would work, but `after_commit` tests require `use_transactional_tests = false`.

```ruby
# Correct: fires after the DB transaction commits
after_commit :invalidate_dashboard_cache, on: %i[create update destroy]

# Wrong: fires inside the transaction — cache deletion may be rolled back
after_save :invalidate_dashboard_cache
```

### 3. `use_transactional_tests = false` for cache invalidation tests

Tests that verify `after_commit` cache behaviour must disable transactional tests:

```ruby
# Must be a top-level class (not nested) for use_transactional_tests to take effect
class DoseLogDashboardCacheTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup do
    @user = users(:verified_user)
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  teardown do
    Rails.cache.clear
    Rails.cache = ActiveSupport::Cache::NullStore.new
    # Clean up records created outside of a transaction
    DoseLog.where(puffs: 99, user: @user, medication: @medication).delete_all
  end
end
```

Key points:
- Swap to `MemoryStore` in setup — fast, no persistence between tests
- Clear + swap to `NullStore` in teardown — ensures a stale cache never bleeds into the next test
- Clean up records manually in teardown since the test transaction isn't rolled back
- The class must be **top-level** (not nested inside another test class) for `use_transactional_tests = false` to take effect

### 4. Store plain scalar hashes, not AR objects

Cache serialization with Solid Cache uses `Marshal`. AR objects include loaded associations, dirty tracking state, and internal ivars. Marshal round-trips are slower and the deserialized object may not behave like a live AR record.

Store only the scalar values the view needs:

```ruby
{
  id:                  m.id,
  name:                m.name,
  standard_dose_puffs: m.standard_dose_puffs,
  sick_day_dose_puffs: m.sick_day_dose_puffs,
  taken:               result.taken,
  scheduled:           result.scheduled,
  status:              result.status   # Ruby symbol — Marshal preserves this
}
```

### 5. Symbol values survive Marshal round-trip

`Solid Cache` uses `Marshal` which preserves Ruby symbols. A `:on_track` symbol stored in the cache comes back as `:on_track`, not `"on_track"`. However, to guard against a future JSON-serialising cache store, prefer `.to_sym` when comparing:

```erb
<%# Safe: .to_sym is a no-op for symbols, converts strings if cache store ever changes %>
<% all_on_track = preventer_adherence.all? { |e| e[:status].to_sym == :on_track } %>
```

### 6. Guard `on: :update` to avoid spurious cache misses

Only bust the cache when fields that the view actually reads have changed. Unrelated writes (e.g. `refilled_at`, course dates) should not invalidate:

```ruby
after_commit -> { invalidate_dashboard_cache }, on: :update,
  if: -> { saved_change_to_name? || saved_change_to_medication_type? ||
           saved_change_to_standard_dose_puffs? || saved_change_to_sick_day_dose_puffs? ||
           saved_change_to_doses_per_day? || saved_change_to_course? }
```

### 7. Pass preloaded associations to avoid N+1 on cache miss

When `.includes(:dose_logs)` is used on the query, the associations are already in memory. Pass them to service objects to avoid a per-record SQL query:

```ruby
.includes(:dose_logs)
.map do |m|
  today_logs = m.dose_logs.select { |dl| dl.recorded_at.to_date == today }
  result = AdherenceCalculator.call(m, today, preloaded_logs: today_logs)
  ...
end
```

### 8. Push filtering to SQL before `.includes`

Ruby-side `.select` filters run after the association is loaded. Push filters to the query so the DB does the work and fewer records are loaded:

```ruby
# Bad: loads all medications then filters in Ruby
.includes(:dose_logs).select { |m| m.doses_per_day.present? }

# Good: SQL WHERE clause excludes nil rows before loading associations
.where.not(doses_per_day: nil).includes(:dose_logs)
```

## Extracting shared invalidation logic

Use `DashboardCacheInvalidatable` concern (model layer) to share the private `invalidate_dashboard_cache` method across models. Include it in any model that should bust the dashboard cache on write:

```ruby
class DoseLog < ApplicationRecord
  include DashboardCacheInvalidatable
  after_commit :invalidate_dashboard_cache, on: %i[create destroy]
  ...
end
```

The concern provides `invalidate_dashboard_cache` as a private method and `DashboardCacheInvalidatable.dashboard_cache_key` as a module-level helper.
