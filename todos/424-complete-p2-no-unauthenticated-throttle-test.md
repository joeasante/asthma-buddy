---
status: pending
priority: p2
issue_id: 424
tags: [code-review, testing, rate-limiting, api]
dependencies: []
---

# No test for unauthenticated API rate limit (10/min)

## Problem Statement

The rate limiting tests only exercise the authenticated throttle (60/min). There is no test verifying the stricter unauthenticated throttle (10/min by IP). An attacker probing the API without a token should hit the limit at 10 requests — this behavior is untested.

## Findings

- **Source**: kieran-rails-reviewer (Finding #3)
- **Location**: `test/controllers/api/v1/rate_limiting_test.rb`
- The rate limiting test also uses its own `auth_headers` helper instead of `ApiTestHelper#api_headers` (inconsistency)

## Proposed Solutions

### Option A: Add unauthenticated throttle test
- **Approach**: Add a test that sends 11 requests without auth and asserts 429 on the 11th
- **Effort**: Small
- **Risk**: Low

## Acceptance Criteria

- [ ] Test sends 11 unauthenticated requests to `/api/v1/symptom_logs`
- [ ] 11th request returns 429
- [ ] Response body is structured JSON error format

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-14 | Created from code review | |

## Resources

- PR #24: https://github.com/joeasante/asthma-buddy/pull/24
