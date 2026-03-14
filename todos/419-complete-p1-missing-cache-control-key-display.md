---
status: pending
priority: p1
issue_id: 419
tags: [code-review, security, cache, api, phi]
dependencies: []
---

# API key display page missing Cache-Control headers

## Problem Statement

The `Settings::ApiKeysController#create` action renders the plaintext API key in HTML, but does not set `Cache-Control: no-store` headers. The `set_cache_headers` method exists in `Api::V1::BaseController` but the web controller inherits from `Settings::BaseController`. The rendered HTML containing the plaintext key could be cached by the browser or intermediate proxies.

## Findings

- **Source**: security-sentinel (Finding #9)
- **Location**: `app/controllers/settings/api_keys_controller.rb:11-17`
- `Api::V1::BaseController` sets `Cache-Control: no-store, no-cache, must-revalidate, private` but this only applies to API responses
- The web controller that actually renders the plaintext key has no cache headers
- The key appears in the DOM at `#api-key-value` and could persist in browser cache

## Proposed Solutions

### Option A: Add cache headers to the create action
- **Approach**: Add `response.headers["Cache-Control"] = "no-store"` in the `create` action or as a `before_action` on `Settings::ApiKeysController`
- **Pros**: One-line fix, targeted
- **Cons**: None
- **Effort**: Small
- **Risk**: Low

## Recommended Action

_To be filled during triage_

## Technical Details

- **Affected files**: `app/controllers/settings/api_keys_controller.rb`

## Acceptance Criteria

- [ ] `create` action response includes `Cache-Control: no-store` header
- [ ] Test verifies the header is present

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-14 | Created from code review | security-sentinel identified cache exposure |

## Resources

- PR #24: https://github.com/joeasante/asthma-buddy/pull/24
- Related: `todos/409-complete-p1-missing-cache-control-health-data.md`
