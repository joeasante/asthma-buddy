---
status: complete
priority: p2
issue_id: "215"
tags: [code-review, security, auth, open-redirect]
dependencies: []
---

# Open Redirect Risk in `after_authentication_url` — Should Use `url_from` for Host Validation

## Problem Statement

`Authentication#request_authentication` stores `request.url` in the session without validating the host:

```ruby
# app/controllers/concerns/authentication.rb, line 40
session[:return_to_after_authenticating] = request.url
```

The stored URL is then redirected to after login:
```ruby
# app/controllers/concerns/authentication.rb, line 47
def after_authentication_url
  session.delete(:return_to_after_authenticating) || root_url
end
```

`request.url` is the full URL including host. If an attacker can get a victim to load a specially-crafted URL before authentication (e.g., via a phishing link), an off-host URL could be stored and the victim redirected there after login.

**Mitigating factor:** Rails 7.1+ `redirect_to` raises `ActionController::Redirecting::UnsafeRedirectError` on cross-host redirects unless `allow_other_host: true` is passed. This Rails-internal guard exists but is implicit — it is not expressed in the code and could be bypassed in future Rails versions or if `allow_other_host: true` is added.

This affects every authenticated endpoint in the app, not just Phase 15.1.

## Findings

**Flagged by:** security-sentinel (P2)

**Location:** `app/controllers/concerns/authentication.rb` lines 40 and 47–49

## Proposed Solutions

### Option A — Use `url_from` to validate host before storing (Recommended)
**Effort:** Small | **Risk:** None

Rails 7.1+ ships `url_from` which returns `nil` for off-host URLs:

```ruby
def request_authentication
  respond_to do |format|
    format.html do
      session[:return_to_after_authenticating] = url_from(request.url) || root_url
      redirect_to new_session_path
    end
    format.json { render json: { error: "Authentication required" }, status: :unauthorized }
  end
end
```

`url_from` explicitly validates that the URL's host matches the current request's host. If it doesn't, it returns `nil` and the fallback `root_url` is stored instead.

**Pros:** Explicit host validation in code. No reliance on Rails internal safety net. Self-documenting.
**Cons:** None.

### Option B — Rely on Rails internal protection (current state)
**Effort:** None | **Risk:** Low (Rails handles it)

Current behaviour relies on `ActionController::Redirecting::UnsafeRedirectError` being raised on cross-host redirect. This works in Rails 7.1+ but is not explicit in code.

## Recommended Action

Option A. The fix is one line. Makes the host validation explicit and independent of Rails internal redirect protection.

## Technical Details

- **Affected files:** `app/controllers/concerns/authentication.rb`
- **Test to add:** `test "request_authentication stores only same-host URL in session"`

## Acceptance Criteria

- [ ] `session[:return_to_after_authenticating]` is set via `url_from(request.url) || root_url`
- [ ] Off-host URLs stored in the session redirect to `root_url` after login
- [ ] All authentication tests still pass

## Work Log

- 2026-03-10: Identified by security-sentinel. Cross-cutting concern affecting all authenticated endpoints.
