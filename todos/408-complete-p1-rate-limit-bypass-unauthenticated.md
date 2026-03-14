---
status: complete
priority: p1
issue_id: "408"
tags: [code-review, security, rate-limiting, api]
dependencies: []
---

# Rate Limit Bypass for Unauthenticated API Requests

## Problem Statement

The Rack::Attack API throttle keys by SHA-256 digest of the Bearer token. Requests without a Bearer token return `nil` as the throttle key, causing Rack::Attack to skip throttling entirely. An attacker can send unlimited requests to `/api/v1/` endpoints without any token — they get 401s but still consume server resources and can brute-force tokens without limit.

## Findings

**Flagged by:** security-sentinel

**Location:** `config/initializers/rack_attack.rb`, lines 31-37

```ruby
throttle("api/v1/requests", limit: 60, period: 1.minute) do |req|
  if req.path.start_with?("/api/v1/")
    token = req.env["HTTP_AUTHORIZATION"]&.match(/\ABearer (.+)\z/)&.[](1)
    Digest::SHA256.hexdigest(token) if token.present?
  end
end
```

When `token` is nil/blank, the block returns `nil` and Rack::Attack does not throttle.

## Proposed Solutions

### Option A: Add IP-based fallback throttle (Recommended)

```ruby
# Throttle unauthenticated API requests by IP (stricter limit)
throttle("api/v1/unauthenticated", limit: 10, period: 1.minute) do |req|
  if req.path.start_with?("/api/v1/")
    token = req.env["HTTP_AUTHORIZATION"]&.match(/\ABearer (.+)\z/)&.[](1)
    req.ip unless token.present?
  end
end
```

- **Pros:** Stops unlimited unauthenticated probing, simple
- **Cons:** Shared IPs (corporate NAT) could hit limit
- **Effort:** Small (5 min)
- **Risk:** Low

## Acceptance Criteria

- [ ] Unauthenticated API requests are throttled by IP
- [ ] Authenticated API requests are still throttled by API key
- [ ] Web requests are unaffected
- [ ] Rate limiting tests updated to cover unauthenticated throttle

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-14 | Created from Phase 28 code review | Security-sentinel flagged |
