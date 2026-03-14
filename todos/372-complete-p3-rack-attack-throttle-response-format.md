---
status: complete
priority: p3
issue_id: 372
tags: [code-review, api, rate-limiting]
dependencies: []
---

## Problem Statement

The Rack::Attack `throttled_responder` always returns `Content-Type: text/plain`. JSON API clients receive a plain text 429 response instead of a properly formatted JSON error body.

## Findings

The current throttled response does not inspect the request's `Accept` header or path to determine the appropriate response format. Any client expecting JSON (e.g., future API consumers or Turbo Stream requests) receives plain text, which may cause parsing errors or unclear error handling on the client side.

## Proposed Solutions

- Inspect the request's `Accept` header or content type in the throttled responder.
- Return JSON (`{ "error": "Too many requests", "retry_after": N }`) when the client accepts JSON.
- Return plain text for other clients as a fallback.
- Include the `Retry-After` header in all throttled responses.

## Technical Details

**Affected files:** config/initializers/rack_attack.rb

## Acceptance Criteria

- [ ] Throttled response returns JSON body when client sends `Accept: application/json`
- [ ] Throttled response falls back to plain text for non-JSON clients
- [ ] `Retry-After` header is included in the 429 response
- [ ] Response content type matches the body format
