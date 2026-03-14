---
phase: 28-rest-api
plan: 01
subsystem: api
tags: [api-key, sha256, settings, rails, security]

requires:
  - phase: 27-mfa
    provides: "Settings::BaseController, SettingsPolicy, settings UI patterns"
provides:
  - "api_key_digest and api_key_created_at columns on users table"
  - "ApiAuthenticatable concern (generate_api_key!, revoke_api_key!, authenticate_by_api_key)"
  - "Settings UI for API key management at /settings/api_key"
affects: [28-02, 28-03, 28-04, 28-05]

tech-stack:
  added: []
  patterns: ["SHA-256 hashed API key storage", "flash-based one-time secret display"]

key-files:
  created:
    - app/models/concerns/api_authenticatable.rb
    - app/controllers/settings/api_keys_controller.rb
    - app/views/settings/api_keys/show.html.erb
    - db/migrate/20260314211111_add_api_key_columns_to_users.rb
    - test/models/user_api_key_test.rb
    - test/controllers/settings/api_keys_controller_test.rb
  modified:
    - app/models/user.rb
    - config/routes.rb
    - app/views/settings/show.html.erb

key-decisions:
  - "One API key per user stored as SHA-256 digest on users table (no separate model)"
  - "Plaintext key passed via flash[:api_key] for one-time display after redirect"
  - "Reused SettingsPolicy :show? for API key controller authorization"

patterns-established:
  - "API key lifecycle: generate returns plaintext once, stored as SHA-256 digest, revoke nils columns"
  - "Flash-based secret display: flash[:api_key] survives redirect but shown only once"

duration: 2min
completed: 2026-03-14
---

# Phase 28 Plan 01: API Key Infrastructure Summary

**SHA-256 hashed API key storage with generate/revoke/authenticate concern and settings management UI**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-14T21:11:06Z
- **Completed:** 2026-03-14T21:13:35Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments
- User model API key concern with generate, revoke, authenticate, and active? methods
- Migration adding api_key_digest (uniquely indexed) and api_key_created_at to users
- Settings UI at /settings/api_key with one-time key display, active status, and revocation
- 20 tests (12 model + 8 controller) all passing, 681 total suite green

## Task Commits

Each task was committed atomically:

1. **Task 1: Migration + User model API key concern** - `09071c4` (feat)
2. **Task 2: Settings UI for API key management + controller tests** - `4143d6e` (feat)

## Files Created/Modified
- `db/migrate/20260314211111_add_api_key_columns_to_users.rb` - Adds api_key_digest and api_key_created_at columns with unique index
- `app/models/concerns/api_authenticatable.rb` - API key generation, hashing, revocation, and authentication
- `app/models/user.rb` - Includes ApiAuthenticatable concern
- `config/routes.rb` - Adds resource :api_key route in settings scope
- `app/controllers/settings/api_keys_controller.rb` - Show/create/destroy actions for key management
- `app/views/settings/api_keys/show.html.erb` - Key management page with one-time display
- `app/views/settings/show.html.erb` - Added API Key navigation card
- `test/models/user_api_key_test.rb` - 12 model tests for key lifecycle
- `test/controllers/settings/api_keys_controller_test.rb` - 8 controller tests

## Decisions Made
- One API key per user on users table (no separate model) -- matches CONTEXT.md locked decision
- Plaintext key passed via flash[:api_key] for one-time display after redirect
- Reused SettingsPolicy :show? for API key controller authorization (same pattern as SecurityController)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- API key infrastructure complete, ready for API base controller and authentication middleware (Plan 02)
- User.authenticate_by_api_key provides the lookup method for Bearer token auth
- No blockers

## Self-Check: PASSED

All 7 key files verified present. Commits 09071c4 and 4143d6e confirmed in git log.

---
*Phase: 28-rest-api*
*Completed: 2026-03-14*
