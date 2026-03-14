---
phase: 28-rest-api
plan: 03
subsystem: api
tags: [rate-limiting, rack-attack, api, security, throttle]

requires:
  - phase: 28-rest-api
    plan: 01
    provides: "API key infrastructure (SHA-256 digest, generate_api_key!)"
provides:
  - "API-specific rate limiting at 60 requests/minute per API key"
  - "429 responses with Retry-After header and JSON error format"
affects: [28-04, 28-05]

tech-stack:
  added: []
  patterns: ["Per-API-key throttling via Rack::Attack", "Retry-After header on 429 responses"]

key-files:
  created:
    - test/controllers/api/v1/rate_limiting_test.rb
  modified:
    - config/initializers/rack_attack.rb

key-decisions:
  - "Throttle key is SHA-256 digest of Bearer token (matches stored digest)"
  - "Retry-After computed from throttle window reset time"
  - "API throttle response uses consistent JSON error format matching API controllers"

duration: 1min
completed: 2026-03-14
---

# Phase 28 Plan 03: API Rate Limiting Summary

**Per-API-key rate limiting at 60 req/min via Rack::Attack with 429 + Retry-After responses**

## Performance

- **Duration:** 1 min
- **Started:** 2026-03-14T21:16:03Z
- **Completed:** 2026-03-14T21:17:19Z
- **Tasks:** 1
- **Files modified:** 2

## Accomplishments

- Added API-specific throttle rule in Rack::Attack for `/api/v1/` paths
- Rate limiting is per API key (SHA-256 digest of Bearer token), not per IP
- 429 responses include `Retry-After` header and consistent JSON error format
- Web requests (login, signup, settings) completely unaffected by API throttle
- 6 tests covering: within-limit success, over-limit 429, Retry-After header, JSON body format, web isolation, independent key limits
- Full suite: 687 tests, 0 failures

## Task Commits

Each task was committed atomically:

1. **Task 1: API rate limiting in Rack::Attack + tests** - `482278f` (feat)

## Files Created/Modified

- `config/initializers/rack_attack.rb` - Added `api/v1/requests` throttle rule (60/min per API key) and API-specific throttled responder with Retry-After header
- `test/controllers/api/v1/rate_limiting_test.rb` - 6 integration tests for API rate limiting

## Decisions Made

- Throttle key is SHA-256 digest of Bearer token (matches how keys are stored in DB)
- Retry-After header computed from throttle window reset: `period - (now % period)`
- API throttle response uses `{ error: { status: 429, message: "...", details: nil } }` format consistent with API controllers

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None.

## Next Phase Readiness

- API rate limiting operational, ready for endpoint implementation (Plans 04-05)
- Existing web rate limits (login, signup) verified unchanged
- No blockers

## Self-Check: PASSED
