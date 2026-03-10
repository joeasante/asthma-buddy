---
status: pending
priority: p2
issue_id: "209"
tags: [code-review, security, performance, rails, rate-limiting]
dependencies: []
---

# `RelieverUsageController` Rate Limit: IP-Keyed, Wrong Ceiling, `render plain:` Response

## Problem Statement

Three separate problems with the `rate_limit` in `RelieverUsageController`:

1. **Keyed to IP, not user session** — users behind a shared NAT or corporate proxy share a single bucket. One user can exhaust the limit for all others. A scraper with a stolen session cookie gets 60 requests/minute undetected.
2. **60 requests/minute** — every other `rate_limit` in the app is `to: 10`. This is the only controller with a 60-limit, and it is applied to a read-only endpoint with no explanation.
3. **`render plain:` for HTML response** — every other controller redirects with a flash message (`redirect_to ..., alert: "..."`) on HTML rate limit. `render plain:` emits bare text with no layout, no proper security headers from the layout, and a broken UX for the user.

## Findings

**Flagged by:** security-sentinel (P2), pattern-recognition-specialist (P2)

**Location:** `app/controllers/reliever_usage_controller.rb` lines 14–19

```ruby
rate_limit to: 60, within: 1.minute, with: -> {
  respond_to do |format|
    format.html { render plain: "Too many requests", status: :too_many_requests }
    format.json { render json: { error: "Too many requests" }, status: :too_many_requests }
  end
}
```

**Codebase convention (from `peak_flow_readings_controller.rb`):**
```ruby
rate_limit to: 10, within: 1.minute, only: :create, with: -> {
  respond_to do |format|
    format.html { redirect_to peak_flow_readings_path, alert: "Too many requests. Please try again." }
    format.json { render json: { error: "Too many requests" }, status: :too_many_requests }
  end
}
```

## Proposed Solutions

### Option A — Fix all three issues (Recommended)
**Effort:** Small | **Risk:** Low

```ruby
rate_limit to: 30, within: 1.minute,
           by: -> { Current.session&.id || request.remote_ip },
           with: -> {
             respond_to do |format|
               format.html { redirect_to reliever_usage_path, alert: "Too many requests. Please slow down.", status: :see_other }
               format.json { render json: { error: "Too many requests" }, status: :too_many_requests }
             end
           }
```

**Pros:** Per-user isolation. Consistent ceiling with rest of app. Consistent HTML handler (redirect + flash).
**Cons:** Minor — no `only:` because this controller only has `index`.

### Option B — Add `by:` and fix `render plain:` only (leave ceiling at 60)
**Effort:** Smaller | **Risk:** Lower

Fixes isolation and broken UX without debating the ceiling.

### Option C — Remove rate limit (endpoint is read-only, auth already protects it)
**Effort:** Smallest | **Risk:** Low — session auth is the primary protection

Other read-only controllers (adherence, peak_flow_readings index) are not rate-limited.

## Recommended Action

Option A. The per-user keying (security), consistent limit (pattern), and redirect response (UX + headers) are all straightforward fixes in one PR.

## Technical Details

- **Affected files:** `app/controllers/reliever_usage_controller.rb`
- **No test changes** — rate limit is not tested in the current test file

## Acceptance Criteria

- [ ] Rate limit is keyed to `Current.session.id` (not `request.remote_ip`)
- [ ] HTML format returns a redirect with flash alert, not `render plain:`
- [ ] Limit is consistent with the rest of the codebase (≤30/min) or removed with justification

## Work Log

- 2026-03-10: Identified by security-sentinel and pattern-recognition-specialist.
