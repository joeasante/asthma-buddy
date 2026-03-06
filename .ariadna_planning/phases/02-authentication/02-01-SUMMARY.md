---
phase: 02-authentication
plan: 01
subsystem: auth
tags: [rails, bcrypt, has_secure_password, sessions, authentication, sqlite]

# Dependency graph
requires:
  - phase: 01-foundation
    provides: Rails app skeleton, ApplicationController, HomeController, layout, routes, test baseline

provides:
  - User model with has_secure_password, email validations, and password min-length enforcement
  - Session model with belongs_to :user (database-backed session tokens via signed cookies)
  - Current model with CurrentAttributes for Current.session and Current.user thread-local access
  - SessionsController (new, create, destroy) for login/logout flow
  - RegistrationsController (new, create) for user signup
  - Authentication concern wired into ApplicationController
  - Signup form at /registration/new, login form at /session/new
  - Users and sessions fixtures (verified_user, unverified_user, alice_session)
  - 28 passing tests: User model tests, RegistrationsController tests, SessionsController tests

affects:
  - 02-02 (email verification gate uses email_verified_at column added here)
  - 02-03 (route guards extend Authentication concern established here)
  - all subsequent phases (auth foundation)

# Tech tracking
tech-stack:
  added: [bcrypt (via has_secure_password), Rails 8 authentication generator]
  patterns:
    - Rails 8 session-cookie auth pattern (signed cookie with session_id, no token in URL)
    - CurrentAttributes for thread-local user/session access (Current.session, Current.user)
    - allow_unauthenticated_access for controllers that should be publicly accessible
    - email_address column convention (Rails 8 generator default, not email)

key-files:
  created:
    - app/models/user.rb
    - app/models/session.rb
    - app/models/current.rb
    - app/controllers/sessions_controller.rb
    - app/controllers/registrations_controller.rb
    - app/controllers/concerns/authentication.rb
    - app/views/sessions/new.html.erb
    - app/views/registrations/new.html.erb
    - db/migrate/20260306212016_create_users.rb
    - db/migrate/20260306212017_create_sessions.rb
    - test/fixtures/users.yml
    - test/fixtures/sessions.yml
    - test/models/user_test.rb
    - test/controllers/registrations_controller_test.rb
    - test/controllers/sessions_controller_test.rb
  modified:
    - app/controllers/application_controller.rb (include Authentication added by generator)
    - app/controllers/home_controller.rb (added allow_unauthenticated_access)
    - config/routes.rb (added resource :registration)
    - test/controllers/passwords_controller_test.rb (fixed for new password policy and layout)

key-decisions:
  - "Rails 8 auth generator uses email_address column (not email) — kept convention rather than renaming"
  - "email_verified_at column added to users now but not enforced until 02-02 (deferred gate)"
  - "HomeController gets allow_unauthenticated_access to keep home page public until 02-03 sets up route guards"
  - "PasswordsControllerTest assert_notice uses p selector to match application layout flash tags"

patterns-established:
  - "allow_unauthenticated_access: any controller action that should be public must explicitly declare this"
  - "Fixtures use verified_user / unverified_user naming to prepare for email verification gate in 02-02"
  - "SessionsController auth tests use verified_user fixture for forward-compatibility with 02-02 email gate"

# Metrics
duration: 3min
completed: 2026-03-06
---

# Phase 2 Plan 01: Authentication Scaffold Summary

**Rails 8 session-cookie auth using has_secure_password — User/Session/Current models, signup and login forms, 28 passing tests including model validations and controller integration tests**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-06T21:20:13Z
- **Completed:** 2026-03-06T21:23:49Z
- **Tasks:** 2 of 2
- **Files modified:** 20+

## Accomplishments

- Generated Rails 8 auth scaffold (User, Session, Current models, Authentication concern, SessionsController, PasswordsController)
- Added email_verified_at column to users table for future email verification gate (02-02)
- Customized User model: email presence/uniqueness/format validation, password minimum 8 chars, email normalization
- Created RegistrationsController with signup form at /registration/new; on success redirects to login with notice
- Updated sessions login view with proper WCAG labels and link to signup page
- Created fixtures (verified_user/unverified_user) and 28 tests covering all auth flows — all green

## Task Commits

Each task was committed atomically:

1. **Task 1: Generate auth scaffold, add RegistrationsController, configure User model** - `0a29900` (feat)
2. **Task 2: Add fixtures, model tests, and integration tests for registration and login** - `5f67dcb` (feat)

## Files Created/Modified

- `app/models/user.rb` - has_secure_password, email validations (presence, uniqueness, format), password min-length, email normalization
- `app/models/session.rb` - belongs_to :user
- `app/models/current.rb` - CurrentAttributes for thread-local session/user access
- `app/controllers/sessions_controller.rb` - Login (new/create) and logout (destroy) with rate limiting
- `app/controllers/registrations_controller.rb` - Signup (new/create) with strong params
- `app/controllers/concerns/authentication.rb` - Authentication concern: resume_session, require_authentication, start_new_session_for, terminate_session
- `app/views/sessions/new.html.erb` - Login form with WCAG labels, forgot password link, signup link
- `app/views/registrations/new.html.erb` - Signup form with WCAG labels, validation error display, login link
- `config/routes.rb` - Added `resource :registration, only: [:new, :create]`
- `db/migrate/20260306212016_create_users.rb` - Users table with email_address (unique index), password_digest, email_verified_at
- `db/migrate/20260306212017_create_sessions.rb` - Sessions table with user_id FK, ip_address, user_agent
- `test/fixtures/users.yml` - verified_user (alice, email_verified_at set) and unverified_user (bob, email_verified_at nil)
- `test/fixtures/sessions.yml` - alice_session linked to verified_user
- `test/models/user_test.rb` - 8 tests: presence, uniqueness, case-insensitive uniqueness, format, normalization, password length
- `test/controllers/registrations_controller_test.rb` - 5 tests: new form, valid create, duplicate email, short password, mismatched confirmation
- `test/controllers/sessions_controller_test.rb` - 5 tests: new form, valid login, wrong password, nonexistent email, logout
- `app/controllers/application_controller.rb` - include Authentication (added by generator)
- `app/controllers/home_controller.rb` - allow_unauthenticated_access for home#index
- `test/controllers/passwords_controller_test.rb` - Fixed to use 8+ char passwords and p tag selector for flash

## Decisions Made

- **Rails 8 generator uses `email_address` column not `email`**: Kept this convention rather than renaming to avoid unnecessary churn — the generated code (SessionsController, Authentication concern, User normalizes) all references `email_address`.
- **email_verified_at added but not enforced**: Column is created now, enforcement (login gate) deferred to 02-02 as specified in plan.
- **HomeController gets `allow_unauthenticated_access`**: The generator auto-inserts `include Authentication` into ApplicationController which adds `before_action :require_authentication`. To keep the root path public (per plan — auth gating is 02-03), HomeController needed this.
- **PasswordsControllerTest assert_notice uses `p` selector**: The generated test used `assert_select "div"` but the app layout uses `<p>` tags for flash messages. Fixed to use `assert_select "p"`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added allow_unauthenticated_access to HomeController**
- **Found during:** Task 1 (auth scaffold generation)
- **Issue:** Generator inserts `include Authentication` into ApplicationController, which adds `before_action :require_authentication` for all controllers. Without `allow_unauthenticated_access` on HomeController, the home page would redirect to login — breaking Phase 1 tests and the intent "Do NOT add before_action authentication yet (that's Plan 02-03)".
- **Fix:** Added `allow_unauthenticated_access only: %i[ index ]` to HomeController
- **Files modified:** `app/controllers/home_controller.rb`
- **Verification:** All tests pass including home controller tests
- **Committed in:** `0a29900` (Task 1 commit)

**2. [Rule 1 - Bug] Fixed PasswordsControllerTest for password policy and flash selector**
- **Found during:** Task 2 (running tests)
- **Issue:** Generated PasswordsControllerTest used password "new" (3 chars, below 8-char minimum) causing update test failure. Also used `assert_select "div"` but layout uses `<p>` tags for flash — causing create/update notice assertions to fail.
- **Fix:** Updated test passwords to "newpassword1"/"nomatch12" (8+ chars); changed `assert_notice` to use `assert_select "p"`.
- **Files modified:** `test/controllers/passwords_controller_test.rb`
- **Verification:** All 28 tests pass
- **Committed in:** `5f67dcb` (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (1 missing critical, 1 bug)
**Impact on plan:** Both auto-fixes necessary for correctness. No scope creep.

## Issues Encountered

None beyond the auto-fixed deviations above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Auth backbone complete: User creation, session-based login/logout, cookie auth
- email_verified_at column in place, ready for 02-02 email verification gate
- Authentication concern in ApplicationController, ready for 02-03 route guards
- All 28 tests green including Phase 1 baseline

---
*Phase: 02-authentication*
*Completed: 2026-03-06*

## Self-Check: PASSED

All key files verified present:
- app/models/user.rb, session.rb, current.rb
- app/controllers/registrations_controller.rb, sessions_controller.rb, concerns/authentication.rb
- app/views/registrations/new.html.erb, sessions/new.html.erb
- test/fixtures/users.yml, sessions.yml
- test/models/user_test.rb, test/controllers/registrations_controller_test.rb, sessions_controller_test.rb
- .ariadna_planning/phases/02-authentication/02-01-SUMMARY.md

All commits verified:
- 0a29900 (Task 1): feat(02-01) generate auth scaffold
- 5f67dcb (Task 2): feat(02-01) add fixtures and tests
