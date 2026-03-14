---
status: pending
priority: p1
issue_id: 417
tags: [code-review, security, rack-attack, api]
dependencies: []
---

# Rack::Attack throttle responder returns inconsistent error format for unauthenticated API requests

## Problem Statement

The `throttled_responder` in `config/initializers/rack_attack.rb` checks `matched == "api/v1/requests"` to return the structured JSON error format with `Retry-After` header. But the unauthenticated throttle rule is named `"api/v1/unauthenticated"` — when it fires, it falls through to the `else` branch which returns `{ error: "message" }` instead of `{ error: { status: 429, message: "...", details: nil } }`. Unauthenticated API callers get a different error shape than authenticated ones.

## Findings

- **Source**: kieran-rails-reviewer, architecture-strategist, pattern-recognition-specialist (cross-validated by 3 agents)
- **Location**: `config/initializers/rack_attack.rb:48-75`
- The `else` branch does check `HTTP_ACCEPT` for JSON content negotiation, but returns a flat `{ error: message }` format
- The structured format with `Retry-After` header is only returned for the authenticated rule

## Proposed Solutions

### Option A: Change condition to match all API throttle rules
- **Approach**: Replace `matched == "api/v1/requests"` with `matched.start_with?("api/v1/")`
- **Pros**: Simple one-line fix, catches any future API throttle rules automatically
- **Cons**: None
- **Effort**: Small
- **Risk**: Low

## Recommended Action

_To be filled during triage_

## Technical Details

- **Affected files**: `config/initializers/rack_attack.rb`
- **Components**: Rate limiting, API error responses

## Acceptance Criteria

- [ ] Both `api/v1/requests` and `api/v1/unauthenticated` throttle rules return `{ error: { status: 429, message: "...", details: nil } }` JSON format
- [ ] Both rules include `Retry-After` header
- [ ] Existing rate limiting tests pass
- [ ] Add test for unauthenticated throttle returning JSON

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-14 | Created from code review | Found by 3 independent review agents |

## Resources

- PR #24: https://github.com/joeasante/asthma-buddy/pull/24
- Related: `todos/408-complete-p1-rate-limit-bypass-unauthenticated.md`
