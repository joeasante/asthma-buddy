---
phase: 24-admin-observability
plan: 01
subsystem: auth
tags: [rails, activerecord, actionmailer, activity-tracking, admin-notifications]

# Dependency graph
requires:
  - phase: 23-compliance-security-accessibility
    provides: Authentication with session management via SessionsController
provides:
  - last_sign_in_at and sign_in_count columns on users table updated on every successful login
  - AdminMailer#new_signup action sending to credentials.admin_email after each new user registration
  - after_create_commit callback on User model enqueuing AdminMailer via deliver_later
affects:
  - 24-02-admin-users-panel (uses admin_users_url route referenced in AdminMailer views)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "update_columns for login metadata — bypasses validations and callbacks, single SQL UPDATE"
    - "after_create_commit with named private method for mailer delivery"
    - "NameError rescue in mailer action for forward-referenced route helper"

key-files:
  created:
    - db/migrate/20260313231818_add_activity_tracking_to_users.rb
    - app/mailers/admin_mailer.rb
    - app/views/admin_mailer/new_signup.html.erb
    - app/views/admin_mailer/new_signup.text.erb
    - config/credentials.example.yml
    - test/mailers/admin_mailer_test.rb
  modified:
    - app/controllers/sessions_controller.rb
    - app/models/user.rb
    - test/fixtures/users.yml
    - test/models/user_test.rb
    - test/controllers/sessions_controller_test.rb
    - test/controllers/registrations_controller_test.rb

key-decisions:
  - "update_columns used for last_sign_in_at/sign_in_count — bypasses validations and callbacks, single SQL UPDATE, correct for tracking metadata"
  - "Local user variable used (not Current.user) because Current is not yet set at the point update_columns is called in SessionsController#create"
  - "NameError rescued in AdminMailer#new_signup to build @admin_users_url — admin_users route added in Plan 24-02; fallback /admin/users string used until then"
  - "assert_enqueued_emails 2 in registrations_controller_test — new signup now enqueues email verification AND admin notification"
  - "include ActiveJob::TestHelper in UserTest to gain access to assert_enqueued_with"

patterns-established:
  - "Login metadata pattern: update_columns after start_new_session_for in SessionsController#create"
  - "Admin notification pattern: after_create_commit private method enqueuing mailer via deliver_later on User"

# Metrics
duration: 12min
completed: 2026-03-13
---

# Phase 24 Plan 01: Activity Tracking + Admin Signup Notifications Summary

**Login activity recorded on every successful sign-in (last_sign_in_at + sign_in_count) and admin notified via ActionMailer after each new user registration.**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-03-13T23:18:14Z
- **Completed:** 2026-03-13T23:30:00Z
- **Tasks:** 2
- **Files modified:** 12 (6 created, 6 modified)

## Accomplishments
- Migration adds `last_sign_in_at` (nullable datetime) and `sign_in_count` (integer, not null, default 0) to users table
- `SessionsController#create` calls `update_columns` after `start_new_session_for` to record login time and increment login count
- `AdminMailer#new_signup` action sends HTML + plain text email to `credentials.admin_email` with user email, name, joined date, and admin link
- `User#after_create_commit` callback enqueues `AdminMailer.new_signup` via `deliver_later` on every new registration
- 7 new tests added across user model, mailer, and sessions controller test files

## Task Commits

Each task was committed atomically:

1. **Task 1: Migration + SessionsController activity tracking** - `878c8ca` (feat)
2. **Task 2: AdminMailer + User callback + tests** - `f41f28e` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified
- `db/migrate/20260313231818_add_activity_tracking_to_users.rb` - Migration for last_sign_in_at and sign_in_count columns
- `app/controllers/sessions_controller.rb` - Added update_columns call after start_new_session_for
- `app/mailers/admin_mailer.rb` - AdminMailer class with new_signup action; NameError rescue for admin_users_url
- `app/views/admin_mailer/new_signup.html.erb` - HTML email view with user details and admin link
- `app/views/admin_mailer/new_signup.text.erb` - Plain text email view with same content
- `app/models/user.rb` - Added after_create_commit :notify_admin_of_signup callback and private method
- `config/credentials.example.yml` - Documents admin_email credential requirement
- `test/fixtures/users.yml` - Added sign_in_count and last_sign_in_at to all three user fixtures
- `test/models/user_test.rb` - Added sign_in_count default test and enqueue assertion test
- `test/mailers/admin_mailer_test.rb` - New: tests recipient, subject, and HTML body
- `test/controllers/sessions_controller_test.rb` - Added 3 activity tracking tests
- `test/controllers/registrations_controller_test.rb` - Updated assert_enqueued_emails 1 → 2

## Decisions Made

- `update_columns` used for login metadata tracking — bypasses validations and callbacks, single SQL UPDATE. Correct approach for tracking metadata.
- Local `user` variable used (not `Current.user`) in SessionsController because `Current.user` is not yet populated immediately after `start_new_session_for`; the session cookie hasn't been re-read yet.
- `NameError` rescued in `AdminMailer#new_signup` to compute `@admin_users_url` — the `admin_users` route is added in Plan 24-02; the fallback `/admin/users` string is used until then. This prevents test failures and nil route errors in CI.
- `include ActiveJob::TestHelper` added to `UserTest` — `assert_enqueued_with` is not available in `ActiveSupport::TestCase` by default.
- Updated `assert_enqueued_emails` from `1` to `2` in `RegistrationsControllerTest` — new user creation now enqueues both the email verification mailer and the admin signup notification.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `admin_users_url` NameError breaks mailer rendering before Plan 24-02**
- **Found during:** Task 2 (AdminMailer + User callback + tests)
- **Issue:** `admin_users_url` route doesn't exist until Plan 24-02. Calling it in the view raised `ActionView::Template::Error: undefined local variable or method 'admin_users_url'` during test execution.
- **Fix:** Rescued `NameError` in `AdminMailer#new_signup` and set `@admin_users_url` ivar; views use `@admin_users_url` instead of calling the route helper directly. At runtime post-Plan 24-02, the route resolves correctly.
- **Files modified:** `app/mailers/admin_mailer.rb`, `app/views/admin_mailer/new_signup.html.erb`, `app/views/admin_mailer/new_signup.text.erb`
- **Verification:** `bin/rails test test/mailers/admin_mailer_test.rb` — 2 tests, 7 assertions, 0 failures
- **Committed in:** `f41f28e` (Task 2 commit)

**2. [Rule 1 - Bug] `RegistrationsControllerTest` expected 1 enqueued email but 2 are now enqueued**
- **Found during:** Task 2 (full suite run after AdminMailer added)
- **Issue:** `assert_enqueued_emails 1` counted only the email verification job. After adding `after_create_commit :notify_admin_of_signup`, user creation enqueues 2 jobs.
- **Fix:** Updated assertion to `assert_enqueued_emails 2` and renamed the test to reflect both emails.
- **Files modified:** `test/controllers/registrations_controller_test.rb`
- **Verification:** Full suite 538 tests, 0 failures
- **Committed in:** `f41f28e` (Task 2 commit)

**3. [Rule 3 - Blocking] `assert_enqueued_with` unavailable in UserTest without helper include**
- **Found during:** Task 2 (user model test)
- **Issue:** `assert_enqueued_with` is from `ActiveJob::TestHelper` which isn't included in `ActiveSupport::TestCase` by default.
- **Fix:** Added `include ActiveJob::TestHelper` to `UserTest`.
- **Files modified:** `test/models/user_test.rb`
- **Verification:** `bin/rails test test/models/user_test.rb` — 14 tests, 0 failures
- **Committed in:** `f41f28e` (Task 2 commit)

---

**Total deviations:** 3 auto-fixed (2 Rule 1 bugs, 1 Rule 3 blocking)
**Impact on plan:** All auto-fixes necessary for test correctness and forward-compatibility. No scope creep.

## Issues Encountered

- `Rails.application.credentials.stub` (Minitest's stub method on credentials object) silently failed to run assertions inside the stub block — the stub returned without executing the block body. Rewrote mailer tests to use the real credentials value directly instead.

## User Setup Required

None - no external service configuration required (admin_email credential already set in the development environment).

## Next Phase Readiness

- Login activity tracking and admin notifications are fully operational
- `AdminMailer` is ready; `@admin_users_url` will automatically resolve to the real URL when Plan 24-02 adds the `admin/users` route
- Plan 24-02 can proceed: add `/admin/users` controller and routes

---
*Phase: 24-admin-observability*
*Completed: 2026-03-13*
