---
status: complete
priority: p2
issue_id: "039"
tags: [code-review, security, csp, log-injection, dos]
dependencies: []
---

# `CspReportsController` Log Injection + No Rate Limit + No Body Size Guard

## Problem Statement

`CspReportsController#create` reads the raw request body and logs it without sanitizing control characters. The endpoint is public, unauthenticated, and has no rate limiting. This creates three risks: log injection via newline/ANSI characters, DoS via log flooding, and memory pressure from large bodies read before truncation.

## Findings

**Flagged by:** kieran-rails-reviewer (P2), security-sentinel (Medium — Finding 5), architecture-strategist (Low)

**Location:** `app/controllers/csp_reports_controller.rb`, line 10

```ruby
Rails.logger.warn "[CSP Violation] #{request.body.read.truncate(500)}"
```

**Three issues:**

**1. Log injection:** `request.body.read` returns raw bytes including `\n`, `\r\n`, and ANSI escape sequences. An attacker POSTing `{"csp":"x\n[CRITICAL] Admin login from 1.2.3.4"}` injects a fake log line. SIEM and log aggregation systems parsing newline-delimited logs will treat the injected line as a separate application event.

**2. Body read before truncation:** `.truncate(500)` truncates the String object after it's been fully read into memory. A request with a 10MB body is read completely into RAM before truncation. On a low-memory host, many concurrent large requests could cause OOM pressure.

**3. No rate limiting:** `/csp-violations` is a public POST endpoint with no `rate_limit`. An attacker can flood it at high volume — each request triggers a synchronous disk write to the Rails log. This is a log amplification / I/O DoS vector.

## Proposed Solutions

### Solution A: Sanitize body + add body size limit + add rate limit (Recommended)
```ruby
class CspReportsController < ActionController::Base
  skip_forgery_protection
  rate_limit to: 10, within: 1.minute, with: -> { head :too_many_requests }

  def create
    body = request.body.read(512).to_s   # read at most 512 bytes
    sanitized = body.gsub(/[\r\n\x1b]/, " ").truncate(500)
    Rails.logger.warn "[CSP Violation] #{sanitized}"
    head :no_content
  end
end
```
- **`request.body.read(512)`** — reads at most 512 bytes, preventing full-body memory allocation
- **`.gsub(/[\r\n\x1b]/, " ")`** — strips newlines and ANSI escape sequences before logging
- **`rate_limit`** — consistent with `sessions#create` and `passwords#create`
- **Effort:** Small
- **Risk:** Low (more restrictive, not less)

### Solution B: Add Content-Type validation
Only process requests with `Content-Type: application/csp-report` or `application/json`:
```ruby
return head :unsupported_media_type unless request.content_type&.start_with?("application/csp-report", "application/json")
```
- **Pros:** Rejects non-browser traffic early.
- **Cons:** Some browsers send `application/reports+json` — need to include all valid CSP report content types.
- **Effort:** Small
- **Risk:** Low

## Recommended Action

Solution A for all three issues (body size limit, log sanitization, rate limit). Optionally add Solution B as an additional layer.

## Technical Details

- **File:** `app/controllers/csp_reports_controller.rb`
- **Route:** `POST /csp-violations` (public, unauthenticated)

## Acceptance Criteria

- [ ] Request body read with a byte limit before truncation
- [ ] Log output contains no newline or ANSI escape characters from request body
- [ ] `/csp-violations` has a rate limit (10/minute or similar)
- [ ] `head :too_many_requests` returned when rate limit exceeded
- [ ] Existing `head :no_content` still returned on success

## Work Log

- 2026-03-07: Created from second-pass code review. Flagged by security-sentinel (Medium), kieran-rails-reviewer (P2).
