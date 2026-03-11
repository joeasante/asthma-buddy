---
phase: 19-notifications
verified: 2026-03-11T09:50:36Z
status: passed
score: 19/19 must-haves verified | security: 0 critical, 0 high | performance: 0 high
performance_findings:
  - check: "5.2"
    name: "No pagination on notification index"
    severity: medium
    file: "app/controllers/notifications_controller.rb"
    line: 8
    detail: "@notifications = Current.user.notifications.newest_first loads all records without limit. Acceptable at current scale but worth revisiting if users accumulate many notifications."
  - check: "1.2"
    name: "Duplicate unread COUNT query on every authenticated page"
    severity: medium
    file: "app/views/layouts/application.html.erb + app/views/layouts/_bottom_nav.html.erb"
    line: 73
    detail: "Two separate Current.user.notifications.unread.count queries fire on every authenticated page render — one in the desktop header (application.html.erb:73) and one in _bottom_nav.html.erb:43. They are fast indexed queries but duplicate work. Acceptable now; could be deduped via a controller before_action or helper memoisation."
---

# Phase 19: Notifications Verification Report

**Phase Goal:** Users receive in-app notifications for actionable events — low medication stock, missed preventer doses, and peak flow reminders. A notification feed at /notifications lists all notifications newest-first; unread notifications show a badge count on the nav bell icon; individual and bulk mark-as-read via Turbo Stream.
**Verified:** 2026-03-11T09:50:36Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| #  | Truth | Status | Evidence |
|----|-------|--------|----------|
| 1  | Notification record can be created with user, notification_type, notifiable polymorphic, body, read=false default | VERIFIED | `app/models/notification.rb` — full model with belongs_to :user, belongs_to :notifiable polymorphic: true optional: true, enum :notification_type, validates :body presence, read default false in migration |
| 2  | Notification.unread scope returns only read=false | VERIFIED | `scope :unread, -> { where(read: false) }` line 15; tested in notification_test.rb |
| 3  | DoseLog after_create_commit triggers low_stock notification with deduplication | VERIFIED | `app/models/dose_log.rb` line 14 `after_create_commit :check_low_stock` → `Notification.create_low_stock_for(medication)`; create_low_stock_for guards with `medication.low_stock?` and `exists?` dedup |
| 4  | MissedDoseCheckJob creates one missed_dose notification per preventer per day, skipping duplicates | VERIFIED | `app/jobs/missed_dose_check_job.rb` — iterates non_courses preventer medications with find_each, checks doses_logged_today < doses_per_day, dedup via `Notification.exists?` scoped to today's date range |
| 5  | PruneNotificationsJob deletes read notifications older than 90 days, never touches unread | VERIFIED | `app/jobs/prune_notifications_job.rb` — `Notification.pruneable.delete_all`; pruneable scope: `where(read: true).where("created_at < ?", 90.days.ago)` |
| 6  | Both jobs scheduled in recurring.yml (MissedDoseCheckJob 9pm daily, PruneNotificationsJob daily) | VERIFIED | `config/recurring.yml` — `missed_dose_check: class: MissedDoseCheckJob, schedule: every day at 9pm` and `prune_notifications: class: PruneNotificationsJob, schedule: every day at 3am` |
| 7  | GET /notifications renders newest-first feed with unread styling, type icon, body, relative timestamp | VERIFIED | `app/controllers/notifications_controller.rb` index: `Current.user.notifications.newest_first`; view renders _notification partial with `notification-row--unread`, type SVG icons, bold body via `notification-body--unread`, time element with `data-controller="relative-time"` |
| 8  | PATCH /notifications/:id/mark_read marks read, updates row via Turbo Stream | VERIFIED | Controller mark_read action: `@notification.update!(read: true)`, responds `format.turbo_stream`; `mark_read.turbo_stream.erb` — `turbo_stream.replace dom_id(@notification)` + `turbo_stream.replace "nav-bell"` |
| 9  | POST /notifications/mark_all_read marks all unread read, updates all rows + removes badge via Turbo Stream | VERIFIED | Controller mark_all_read: `Current.user.notifications.unread.update_all(read: true)`, `@unread_count = 0`; `mark_all_read.turbo_stream.erb` replaces each notification row + replaces nav-bell with count 0 |
| 10 | Nav bell icon shows CSS ::after unread badge when unread count > 0; disappears at zero | VERIFIED | `_nav_bell.html.erb` — `class="nav-bell has-unread-badge"` with `data-unread-count: unread_count`; `notifications.css` line 162 — `.has-unread-badge[data-unread-count]:not([data-unread-count="0"])::after` renders red dot |
| 11 | Bottom nav Notifications tab replaces Medications tab; Medications remains in desktop header | VERIFIED | `_bottom_nav.html.erb` — Notifications/Alerts tab with bell SVG; `application.html.erb` line 67 still contains `link_to "Medications", settings_medications_path` in desktop nav |
| 12 | Clicking notification navigates to relevant path; broken notifiable rescued, auto-marks read | VERIFIED | Controller `resolve_notification_path` — per-type begin/rescue blocks, `notification.update_columns(read: true)` before safe fallback; low_stock → settings_medications_path, missed_dose → root_path |
| 13 | relative_time_controller.js renders human-friendly timestamps updating every 60s | VERIFIED | `app/javascript/controllers/relative_time_controller.js` — 60s `setInterval`, pure JS `format()` with threshold-based strings; auto-discovered by `eagerLoadControllersFrom` (filename convention) |
| 14 | Empty state "You're all caught up." shown when no notifications or all read | VERIFIED | `notifications/index.html.erb` — `if @notifications.empty?` renders empty-state div with that text; `if @notifications.all?(&:read)` renders `notifications-all-read` paragraph with same text |
| 15 | Controller test: index scoped to Current.user, unauthenticated redirects | VERIFIED | `test/controllers/notifications_controller_test.rb` — 11 tests: index 200, user-scoped listing (Bob's body absent), unauthenticated redirect |
| 16 | Controller test: mark_read marks read, returns Turbo Stream, 404 cross-user, redirect unauthenticated | VERIFIED | Tests: mark_read marks read + reloads, Turbo Stream media type asserted, 404 for @bob_notif, unauthenticated redirect |
| 17 | Controller test: mark_all_read marks all unread for user, Turbo Stream, preserves other users' state | VERIFIED | Tests: unread count → 0 after call, Turbo Stream media type, @bob_notif state unchanged, unauthenticated redirect |
| 18 | System test: badge visible, mark single inline, mark all read, empty states | VERIFIED | `test/system/notifications_test.rb` — 7 tests: badge `[data-unread-count]:not([data-unread-count='0'])`, nav-bell data-unread-count='0' after mark all, inline row update via turbo frame, all rows read after mark all, empty state both cases |
| 19 | System test: Medications link remains in desktop header after bottom nav change | VERIFIED | Test asserts `header a[href*='settings/medications']` still present |

**Score:** 19/19 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `db/migrate/20260311093356_create_notifications.rb` | Notifications table with indexes | VERIFIED | Creates table with user_id FK, notifiable polymorphic (nullable), notification_type int, body string, read bool default false; composite index [user_id, read], index [notifiable_type, notifiable_id] |
| `app/models/notification.rb` | Model with enum, scopes, create_low_stock_for | VERIFIED | 34 lines; belongs_to :user, belongs_to :notifiable polymorphic optional, enum validate:true, body validation, unread/newest_first/pruneable scopes, create_low_stock_for class method |
| `app/jobs/missed_dose_check_job.rb` | Solid Queue job with dedup | VERIFIED | 44 lines; non_courses preventer medications, find_each, doses count check, Notification.exists? dedup, Notification.create! |
| `app/jobs/prune_notifications_job.rb` | Pruning job | VERIFIED | 9 lines; `Notification.pruneable.delete_all` |
| `config/recurring.yml` | Recurring schedule | VERIFIED | missed_dose_check at 9pm daily, prune_notifications at 3am daily |
| `app/controllers/notifications_controller.rb` | index, mark_read, mark_all_read; scoped | VERIFIED | 67 lines; before_action :require_authentication, scoped to Current.user, resolve_notification_path with RecordNotFound rescue |
| `app/views/notifications/index.html.erb` | Feed with empty state | VERIFIED | 29 lines; page-header, mark-all-read button (conditional), notification list, empty state |
| `app/views/notifications/_notification.html.erb` | Notification row partial | VERIFIED | 50 lines; turbo_frame_tag dom_id, unread dot, type SVG icons (3 types), bold unread body, relative-time Stimulus, mark-read button_to |
| `app/views/notifications/mark_read.turbo_stream.erb` | Turbo Stream single row + badge | VERIFIED | Replaces dom_id(@notification) row + replaces nav-bell partial |
| `app/views/notifications/mark_all_read.turbo_stream.erb` | Turbo Stream all rows + badge zero | VERIFIED | Replaces each notification row + nav-bell with count 0 |
| `app/views/layouts/_nav_bell.html.erb` | Bell icon partial with unread badge data | VERIFIED | id="nav-bell", class="nav-bell has-unread-badge", data-unread-count: unread_count, aria-label with count |
| `app/assets/stylesheets/notifications.css` | Feed styles + badge ::after | VERIFIED | 221 lines; unread row background, type icon colours, notification dot, btn-mark-read, .has-unread-badge CSS ::after badge, empty state styles, reduced-motion media query |
| `app/javascript/controllers/relative_time_controller.js` | Stimulus relative time, 60s refresh | VERIFIED | 33 lines; datetimeValue, 60s setInterval, threshold-based format() |
| `test/controllers/notifications_controller_test.rb` | 11 controller integration tests | VERIFIED | 103 lines; 11 tests covering index (auth, scoping), mark_read (success, Turbo Stream, cross-user 404), mark_all_read (marks all, Turbo Stream, cross-user isolation), unauthenticated redirects |
| `test/system/notifications_test.rb` | 7 system tests | VERIFIED | 117 lines; badge visibility, badge zeroed after mark all, inline row update, all rows cleared, empty state (2 cases), Medications regression |
| `test/fixtures/notifications.yml` | 4 fixtures: alice_low_stock, alice_missed_dose, alice_read_old, bob_notification | VERIFIED | All 4 fixtures present with correct polymorphic notifiable_id via ActiveRecord::FixtureSet.identify |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `app/models/dose_log.rb` | `Notification.create_low_stock_for(medication)` | after_create_commit callback | WIRED | `after_create_commit :check_low_stock` → `Notification.create_low_stock_for(medication)` present on line 14 and 18-20 |
| `app/jobs/missed_dose_check_job.rb` | `Notification.exists?` | dedup check before create | WIRED | `Notification.exists?(...)` present on line 27 |
| `config/recurring.yml` | MissedDoseCheckJob / PruneNotificationsJob | Solid Queue recurring schedule | WIRED | Both class names present in recurring.yml under production block |
| `app/views/notifications/_notification.html.erb` | `notifications#mark_read` | turbo_frame_tag + button_to PATCH | WIRED | `mark_read_notification_path(notification)` present with method: :patch |
| `app/views/notifications/index.html.erb` | `notifications#mark_all_read` | button_to POST | WIRED | `mark_all_read_notifications_path` with method: :post present |
| `app/views/layouts/application.html.erb` | `Notification.unread.count` | data-unread-count on bell | WIRED | `unread_count = Current.user.notifications.unread.count` then rendered via `_nav_bell` partial with `data-unread-count: unread_count` |
| `app/views/notifications/mark_read.turbo_stream.erb` | bell button data-unread-count | turbo_stream.replace "nav-bell" | WIRED | `turbo_stream.replace "nav-bell"` present, renders layouts/nav_bell partial with @unread_count |

### Requirements Coverage

Not applicable — requirements.md phase mapping not checked; phase goal fully covered by truth verification above.

### Anti-Patterns Found

No anti-patterns detected in phase 19 files. No TODO/FIXME/PLACEHOLDER comments, no debug statements, no empty implementations, no NotImplementedError stubs.

### Security Findings

Brakeman: 0 warnings. Bundler-audit: 0 vulnerabilities.

Manual checks (applicable to controller and model files):

| Check | Name | Severity | File | Line | Detail |
|-------|------|----------|------|------|--------|
| 3.2 | Scoped resource lookup | PASS | `app/controllers/notifications_controller.rb` | 39 | `Current.user.notifications.find(params[:id])` — correctly scoped through user association, not Notification.find |
| 3.1 | Authentication guard | PASS | `app/controllers/notifications_controller.rb` | 4 | `before_action :require_authentication` covers all actions |
| 2.1 | CSRF protection | PASS | Inherits from ApplicationController; no skip_forgery_protection |
| 1.1 | SQL injection | PASS | No string interpolation in queries; all parameterised via ActiveRecord |

**Security:** 0 findings (0 critical, 0 high, 0 medium)

### Performance Findings

| Check | Name | Severity | File | Line | Detail |
|-------|------|----------|------|------|--------|
| 5.2 | No pagination on notification feed | medium | `app/controllers/notifications_controller.rb` | 8 | `Current.user.notifications.newest_first` loads all records. At current user scale this is acceptable; worth revisiting when a user could accumulate hundreds of notifications. |
| 1.2 | Duplicate unread COUNT query per page | medium | `app/views/layouts/application.html.erb` + `app/views/layouts/_bottom_nav.html.erb` | 73 / 43 | Two independent `Current.user.notifications.unread.count` SQL calls fire on every authenticated page render (desktop header + bottom nav). Both hit the `[user_id, read]` composite index so they are fast, but they are duplicated work. Could be resolved with a helper method memoised via `@unread_count ||=`. |

**Performance:** 2 findings (0 high, 2 medium, 0 low) — no blocking threshold reached.

### Human Verification Required

#### 1. Unread badge renders visually on bell icon

**Test:** Sign in, create a notification via `Notification.create!(...)` in rails console, navigate to any page
**Expected:** Red dot appears top-right of bell icon in desktop header
**Why human:** CSS ::after pseudo-element rendering cannot be verified with grep

#### 2. Badge disappears after mark all read

**Test:** Visit /notifications, click "Mark all read"
**Expected:** Red dot on bell disappears immediately via Turbo Stream (no page reload)
**Why human:** Real-time Turbo Stream DOM update visible only in browser

#### 3. Relative timestamps refresh

**Test:** Visit /notifications, wait 60+ seconds
**Expected:** "just now" → "1 minute ago" (or appropriate transition)
**Why human:** Time-dependent JS interval behaviour

#### 4. Missed dose notification flow end-to-end

**Test:** Enqueue MissedDoseCheckJob via `MissedDoseCheckJob.perform_later` after midnight with no preventer dose logged
**Expected:** Notification created and visible in feed
**Why human:** Requires Solid Queue worker running and real preventer medication with doses_per_day set

### Gaps Summary

No gaps. All 19 observable truths are verified by substantive, wired artifacts. The two medium performance findings (missing pagination, duplicate count query) are acceptable at current scale and do not block the phase goal.

---

_Verified: 2026-03-11T09:50:36Z_
_Verifier: Claude (ariadna-verifier)_
