---
status: complete
priority: p3
issue_id: 367
tags: [code-review, security, rate-limiting]
dependencies: []
---

## Problem Statement

The Rack::Attack login throttle is IP-only (5 requests per 20 seconds per IP). Distributed brute-force attacks across many IPs targeting a single account bypass this limit entirely, as there is no account-level throttling.

## Findings

The current rate-limiting configuration only tracks requests by IP address. An attacker using a botnet or rotating proxies can attempt many passwords against a single account without triggering any throttle, since each IP stays under the per-IP limit.

## Proposed Solutions

- Add a second throttle keyed on the login email/username parameter (e.g., `req.params.dig('email_address')`).
- Use a lower limit for per-account throttling (e.g., 10 attempts per 5 minutes per account).
- Consider exponential backoff or temporary account lockout after repeated failures.
- Ensure the account-level throttle uses a normalized (downcased/stripped) email to prevent bypass via case variations.

## Technical Details

**Affected files:** config/initializers/rack_attack.rb

## Acceptance Criteria

- [ ] Account-level throttle added for login endpoint keyed on email parameter
- [ ] Per-account limit is reasonable (e.g., 10 attempts per 5 minutes)
- [ ] Email parameter is normalized before use as throttle key
- [ ] Existing IP-based throttle remains in place
- [ ] Tests cover both IP-based and account-based throttling
