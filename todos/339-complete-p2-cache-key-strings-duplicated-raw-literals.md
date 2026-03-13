---
status: pending
priority: p2
issue_id: "339"
tags: [code-review, caching, dry, rails, maintainability]
dependencies: []
---

# Cache key strings duplicated as raw literals across multiple files

## Problem Statement

Both cache key formats are hard-coded interpolated strings repeated verbatim in multiple production files and test files, with no single authoritative definition.

**`"unread_notifications/#{user_id}"` appears in:**
- `app/models/notification.rb` (line 43 — `invalidate_badge_cache`)
- `app/controllers/application_controller.rb` (line 34 — `set_notification_badge_count`)
- `app/controllers/notifications_controller.rb` (line 50 — `mark_all_read` explicit delete)
- `test/models/notification_test.rb` (multiple lines)
- `test/controllers/notifications_controller_test.rb` (multiple lines)

**`"dashboard_vars/#{user_id}/#{Date.current}"` appears in:**
- `app/models/dose_log.rb` (line 36 — `invalidate_dashboard_cache`)
- `app/models/health_event.rb` (line 97 — `invalidate_dashboard_cache`)
- `app/controllers/concerns/dashboard_variables.rb` (line 16 — `fetch`)
- `test/models/dose_log_test.rb` (multiple lines)
- `test/models/health_event_test.rb` (multiple lines)
- `test/controllers/dashboard_controller_test.rb` (multiple lines)

If the key format changes (namespace prefix, version segment, bug fix), every occurrence must be found and updated manually. A test that uses the old string while production uses the new one will silently pass while the cache is broken in production.

Flagged by: pattern-recognition-specialist, architecture-strategist (Phase 22 code review).

## Findings

Verified by grep:
- `grep -rn "unread_notifications" app/ test/` — 3 production files, 2 test files
- `grep -rn "dashboard_vars" app/ test/` — 3 production files, 3 test files

## Proposed Solutions

### Option A: Class methods on the owning model (Recommended)

```ruby
# app/models/notification.rb
def self.badge_cache_key(user_id)
  "unread_notifications/#{user_id}"
end
```

```ruby
# app/controllers/concerns/dashboard_variables.rb (or a shared CacheKeys module)
def self.dashboard_cache_key(user_id, date = Date.current)
  "dashboard_vars/#{user_id}/#{date}"
end
```

All callers — models, controllers, tests — reference `Notification.badge_cache_key(user_id)` and `DashboardVariables.dashboard_cache_key(user_id)`. One definition, one place to change.

- **Pros:** Single definition, renaming is one-line change, tests automatically use the live key
- **Cons:** Slightly more verbose call sites
- **Effort:** Small
- **Risk:** Low

### Option B: Module constants (lambdas)

```ruby
BADGE_CACHE_KEY     = ->(user_id)       { "unread_notifications/#{user_id}" }
DASHBOARD_CACHE_KEY = ->(user_id, date) { "dashboard_vars/#{user_id}/#{date}" }
```

- **Pros:** Compact
- **Cons:** Lambda call syntax is less idiomatic than a class method in Rails
- **Effort:** Small
- **Risk:** Low

## Recommended Action

Option A. Class methods are idiomatic Rails and make the intent clear at call sites.

## Technical Details

**Affected files (production):**
- `app/models/notification.rb` — add `self.badge_cache_key`
- `app/controllers/application_controller.rb` — use `Notification.badge_cache_key`
- `app/controllers/notifications_controller.rb` — use `Notification.badge_cache_key`
- `app/controllers/concerns/dashboard_variables.rb` — add `self.dashboard_cache_key`, use in `fetch`
- `app/models/dose_log.rb` — use `DashboardVariables.dashboard_cache_key`
- `app/models/health_event.rb` — use `DashboardVariables.dashboard_cache_key`
- (After 337 is resolved) `app/models/medication.rb` — use `DashboardVariables.dashboard_cache_key`

**Affected files (tests):**
- `test/models/notification_test.rb`
- `test/controllers/notifications_controller_test.rb`
- `test/models/dose_log_test.rb`
- `test/models/health_event_test.rb`
- `test/controllers/dashboard_controller_test.rb`

## Acceptance Criteria

- [ ] `Notification.badge_cache_key(user_id)` class method exists and is used at all call sites
- [ ] `DashboardVariables.dashboard_cache_key(user_id, date)` class method exists and is used at all call sites
- [ ] No raw `"unread_notifications/..."` or `"dashboard_vars/..."` string literals remain outside the defining method
- [ ] Tests reference the class methods (not hard-coded strings)
- [ ] Full test suite passes

## Work Log

- 2026-03-13: Identified in Phase 22 code review (pattern-recognition-specialist, architecture-strategist)
