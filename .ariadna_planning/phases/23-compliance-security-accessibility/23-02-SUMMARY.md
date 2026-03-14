---
phase: 23-compliance-security-accessibility
plan: 02
subsystem: infra
tags: [rack-attack, rate-limiting, rails, security]

# Dependency graph
requires:
  - phase: 23-compliance-security-accessibility/23-01
    provides: rack-attack throttle rules for logins/ip and signups/ip
provides:
  - context-specific 429 error messages that tell users exactly what happened and when to retry
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "throttled_responder branches on req.env[\"rack.attack.matched\"] to return context-specific messages per throttle name"

key-files:
  created: []
  modified:
    - config/initializers/rack_attack.rb

key-decisions:
  - "throttled_responder receives req (Rack::Attack::Request), not raw env hash — rack.attack.matched is accessible via req.env[\"rack.attack.matched\"]"
  - "catch-all else branch added to throttled_responder so any future throttle name gets a sensible generic fallback"

patterns-established:
  - "Throttle message branching pattern: case req.env[\"rack.attack.matched\"] with one branch per throttle name plus catch-all else"

requirements_covered: []

# Metrics
duration: 1min
completed: 2026-03-13
---

# Phase 23 Plan 02: Compliance, Security, Accessibility — Throttle Message Gap Closure Summary

**throttled_responder now branches on rack.attack.matched to return a login-specific 20-second retry message and a signup-specific hourly-limit message, closing the UAT gap where users saw only "try again later".**

## Performance

- **Duration:** ~1 min
- **Started:** 2026-03-13T21:33:27Z
- **Completed:** 2026-03-13T21:33:54Z
- **Tasks:** 1 completed
- **Files modified:** 1

## Accomplishments
- Replaced generic `_env` lambda with a `req`-receiving lambda that reads `req.env["rack.attack.matched"]`
- Login throttle ("logins/ip") now returns "Too many sign-in attempts. Please wait 20 seconds before trying again."
- Signup throttle ("signups/ip") now returns "Too many sign-up attempts from this IP address. Please try again later."
- Catch-all `else` branch provides a sensible fallback for any future throttle names
- All 3 rate limiting integration tests pass; full 531-test suite passes with no regressions

## Task Commits

Each task was committed atomically:

1. **Task 1: Differentiate throttle error messages by match name** - `c277597` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified
- `config/initializers/rack_attack.rb` - throttled_responder updated to branch on rack.attack.matched with login/signup/fallback messages

## Decisions Made
- `throttled_responder` receives a `Rack::Attack::Request` object (not a raw Rack env hash) in rack-attack 6.x. The correct parameter name is `req`, not `_env`. `req.env["rack.attack.matched"]` contains the throttle name string set by `Rack::Attack::Check#matched_by?`.
- A catch-all `else` branch was added so any future throttle rules get a generic-but-sensible fallback message without requiring another change to this file.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness
- Rate limiting is now fully actionable: users see specific guidance for login and signup throttle events.
- No blockers. Phase 23 compliance and security work is complete.

---
*Phase: 23-compliance-security-accessibility*
*Completed: 2026-03-13*

## Self-Check: PASSED

- FOUND: `config/initializers/rack_attack.rb`
- FOUND: `23-02-SUMMARY.md`
- FOUND: commit `c277597`
