---
phase: 22-request-path-caching
verified: 2026-03-13T07:31:48Z
status: passed
score: 10/10 must-haves verified | security: 0 critical, 0 high | performance: 0 high
---

# Phase 22: Request-Path Caching Verification Report

**Phase Goal:** The two highest-frequency database reads on every authenticated request are served from Solid Cache rather than hitting the primary database on every page load: (1) the unread notification badge count, which fires on every authenticated request via `ApplicationController#set_notification_badge_count`; (2) the dashboard aggregate variables (`@preventer_adherence`, `@reliever_medications`, `@active_illness`), which fire on every dashboard load and on every Turbo Stream response after dose log actions in Settings.
**Verified:** 2026-03-13T07:31:48Z
**Status:** passed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

#### Plan 01 — Badge Count Cache

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Every authenticated page load reads the badge count from cache, not the database | VERIFIED | `ApplicationController#set_notification_badge_count` wraps `Current.user.notifications.unread.count` in `Rails.cache.fetch("unread_notifications/#{user_id}", expires_in: 1.hour)` — L32-39 of `application_controller.rb` |
| 2 | Creating a new notification immediately invalidates the badge count cache | VERIFIED | `Notification` has `after_commit -> { invalidate_badge_cache }, on: :create` (L22); `invalidate_badge_cache` calls `Rails.cache.delete("unread_notifications/#{user_id}")` (L43-44) |
| 3 | Marking a notification as read immediately invalidates the badge count cache | VERIFIED | `after_commit -> { invalidate_badge_cache }, on: :update, if: :saved_change_to_read?` (L23); guard prevents spurious invalidation on non-`read` updates |
| 4 | Badge count shown in the UI is always consistent with the actual unread row count | VERIFIED | Cache invalidated on every mutation path (create, mark-as-read); 1h TTL is a safety net only; 4 tests covering write, cache-hit, invalidation-on-create, invalidation-on-read, and non-invalidation on other fields |

#### Plan 02 — Dashboard Vars Cache

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 5 | Dashboard page load reads preventer adherence, reliever medications, and active illness from cache on repeated loads | VERIFIED | `DashboardVariables#set_dashboard_vars` wraps all three queries in `Rails.cache.fetch("dashboard_vars/#{user.id}/#{today}", expires_in: 5.minutes)` (L16-36 of `dashboard_variables.rb`) |
| 6 | Logging a dose immediately invalidates the dashboard vars cache for the logging user | VERIFIED | `DoseLog` has `after_commit -> { invalidate_dashboard_cache }, on: :create` (L16); `invalidate_dashboard_cache` deletes `dashboard_vars/#{user_id}/#{Date.current}` (L35-37) |
| 7 | Deleting a dose immediately invalidates the dashboard vars cache | VERIFIED | `DoseLog` has `after_commit -> { invalidate_dashboard_cache }, on: :destroy` (L17) |
| 8 | Creating, updating, or destroying a health event immediately invalidates the dashboard vars cache | VERIFIED | `HealthEvent` has all three: `on: :create` (L45), `on: :update` (L46), `on: :destroy` (L47); `invalidate_dashboard_cache` at L96-98 |
| 9 | Cache key rotates at midnight so today's adherence status is never stale from yesterday | VERIFIED | Cache key includes `Date.current` (`"dashboard_vars/#{user.id}/#{today}"`); yesterday's key is a different string and is never read after midnight |
| 10 | Dashboard data shown is always consistent with the current DB state | VERIFIED | All write paths (create/destroy DoseLog, create/update/destroy HealthEvent) trigger cache deletion; 7 tests cover population and all invalidation paths |

**Score:** 10/10 truths verified

---

### Required Artifacts

#### Plan 01

| Artifact | Expected | Level 1 (Exists) | Level 2 (Substantive) | Level 3 (Wired) | Status |
|----------|----------|------------------|-----------------------|-----------------|--------|
| `app/controllers/application_controller.rb` | Cache-backed `set_notification_badge_count` | PRESENT | Contains `Rails.cache.fetch` with `"unread_notifications/#{user_id}"` key and 1h TTL | Registered as `before_action :set_notification_badge_count, if: :authenticated?` (L23) | VERIFIED |
| `app/models/notification.rb` | Cache invalidation callbacks on create and read update | PRESENT | Contains `after_commit -> { invalidate_badge_cache }` on create and update with `saved_change_to_read?` guard; `invalidate_badge_cache` calls `Rails.cache.delete` | Callbacks are class-level declarations, fire on every commit for the relevant events | VERIFIED |

#### Plan 02

| Artifact | Expected | Level 1 (Exists) | Level 2 (Substantive) | Level 3 (Wired) | Status |
|----------|----------|------------------|-----------------------|-----------------|--------|
| `app/controllers/concerns/dashboard_variables.rb` | Cache-backed `set_dashboard_vars` | PRESENT | Contains `Rails.cache.fetch("dashboard_vars/#{user.id}/#{today}", expires_in: 5.minutes)` wrapping all three variable computations | Included in `DashboardController` (L4) and `Settings::BaseController` (L4); called directly in `DashboardController#index` (L100) and `Settings::DoseLogsController` actions (L34) | VERIFIED |
| `app/models/dose_log.rb` | Cache invalidation on create and destroy | PRESENT | Contains `invalidate_dashboard_cache` private method with `Rails.cache.delete`; wired to both create and destroy via lambda `after_commit` callbacks | Callbacks registered at class level (L16-17) | VERIFIED |
| `app/models/health_event.rb` | Cache invalidation on create, update, and destroy | PRESENT | Contains `invalidate_dashboard_cache` private method (L96-98); wired to create, update, and destroy | Callbacks registered at class level (L45-47) | VERIFIED |

---

### Key Link Verification

| From | To | Via | Status | Detail |
|------|----|-----|--------|--------|
| `app/models/notification.rb` | `Rails.cache.delete("unread_notifications/...")` | `after_commit -> { invalidate_badge_cache }, on: :create/update` | WIRED | Lambda callbacks verified at L22-23; `invalidate_badge_cache` at L42-44 |
| `app/controllers/application_controller.rb` | `Rails.cache.fetch("unread_notifications/...")` | `set_notification_badge_count` before_action | WIRED | `Rails.cache.fetch` at L33-38; registered as before_action at L23 |
| `app/models/dose_log.rb` | `Rails.cache.delete("dashboard_vars/...")` | `after_commit on: :create / :destroy` | WIRED | Lambda callbacks at L16-17; `invalidate_dashboard_cache` at L35-37 |
| `app/models/health_event.rb` | `Rails.cache.delete("dashboard_vars/...")` | `after_commit on: :create / :update / :destroy` | WIRED | Lambda callbacks at L45-47; `invalidate_dashboard_cache` at L96-98 |
| `app/controllers/concerns/dashboard_variables.rb` | `Rails.cache.fetch("dashboard_vars/...")` | `set_dashboard_vars` private method | WIRED | `Rails.cache.fetch` at L16; concern included in both consuming controllers |

---

### Test Coverage

| Test Class | File | Tests | Covers |
|-----------|------|-------|--------|
| `NotificationTest::CacheInvalidationTest` | `test/models/notification_test.rb` | 3 | Create invalidates badge cache; mark-as-read invalidates; non-read field update does not invalidate |
| `BadgeCacheTest` | `test/controllers/notifications_controller_test.rb` | 1 | Badge cache written on first authenticated request, persists on second request |
| `DoseLogDashboardCacheTest` | `test/models/dose_log_test.rb` | 2 | Create invalidates dashboard cache; destroy invalidates dashboard cache |
| `HealthEventDashboardCacheTest` | `test/models/health_event_test.rb` | 3 | Create, update, and destroy each invalidate dashboard cache |
| `DashboardVarsCacheTest` | `test/controllers/dashboard_controller_test.rb` | 2 | Dashboard vars written to cache on first load; cache read-path verified with sentinel overwrite pattern |

**Test suite:** 515 runs, 1344 assertions, 0 failures, 0 errors, 0 skips

---

### Notable Implementation Decisions (Verified Correct)

**Lambda callbacks instead of symbol form:** All three models use `after_commit -> { method }, on: :event` rather than `after_create_commit :method`. This bypasses Rails' `_commit_callbacks` deduplication-by-filter-symbol behaviour — if the same method name were registered via `after_create_commit :method` and `after_update_commit :method`, only the last declaration survives. The lambda form creates a unique Proc object for each registration, so all callbacks fire. This was caught and fixed during Plan 01 Task 2.

**`use_transactional_tests = false` in cache test classes:** `after_commit` callbacks only fire when a DB transaction actually commits. Rails default test mode wraps each test in a rolled-back transaction, so callbacks never run. Cache invalidation tests are placed as top-level classes (not nested) with `self.use_transactional_tests = false` and explicit `teardown` cleanup, which is the correct pattern for Rails 8's parallel test runner.

**`DoseLog` mixes symbol and lambda forms safely:** `after_create_commit :check_low_stock` (symbol, L15) and `after_commit -> { invalidate_dashboard_cache }, on: :create` (lambda, L16) coexist without conflict because they reference different method names — Rails deduplication only collapses identical filter values, and a symbol and a Proc are never equal.

---

### Anti-Patterns Found

None. No TODOs, FIXMEs, placeholders, debug statements, or empty implementations in any changed file.

---

### Security Findings

Brakeman: 0 warnings (clean). No SQL injection, mass assignment, IDOR, or other vulnerabilities introduced.

**Security:** 0 findings (0 critical, 0 high, 0 medium)

---

### Performance Findings

No regressions. The phase purpose is performance improvement — it eliminates repeated DB reads on every authenticated request. The concern uses `.includes(:dose_logs)` (L20, L26) to avoid N+1 queries within the cached computation block.

**Performance:** 0 findings

---

### Human Verification Required

None required. All assertions are verifiable programmatically via the test suite, which is fully green.

---

### Summary

Phase 22 fully achieves its goal. Both highest-frequency DB reads on authenticated requests are now cache-backed:

1. **Badge count** (`unread_notifications/{user_id}`, 1h TTL): served from Solid Cache on every authenticated request after first load; invalidated immediately on notification create or mark-as-read; guarded so non-read field updates do not clear the cache.

2. **Dashboard vars** (`dashboard_vars/{user_id}/{Date.current}`, 5m TTL): served from Solid Cache on repeated dashboard loads and Turbo Stream responses; invalidated immediately on any DoseLog or HealthEvent write; cache key includes `Date.current` for natural midnight rotation ensuring adherence calculations are never stale across a day boundary.

All 10 observable truths are verified. All 5 required artifacts exist, are substantive, and are correctly wired. 11 new cache tests cover every invalidation path. Full test suite green at 515 tests. Brakeman clean. RuboCop clean.

---

_Verified: 2026-03-13T07:31:48Z_
_Verifier: Claude (ariadna-verifier)_
