---
status: pending
priority: p3
issue_id: "305"
tags: [code-review, rails, security, documentation, authentication]
dependencies: []
---

# url_from open-redirect fix lacks an explanatory comment

## Problem Statement
`app/controllers/concerns/authentication.rb` changed `session[:return_to_after_authenticating] = request.url` to `session[:return_to_after_authenticating] = url_from(request.url) || root_url`. The fix is correct — `url_from` validates the URL is same-origin and returns nil for external URLs. However, without an inline comment explaining why `url_from` is used instead of `request.url`, a future developer may "simplify" it back to the original, reintroducing the open redirect vulnerability.

## Findings
**Flagged by:** security-sentinel (L-1)

**File:** `app/controllers/concerns/authentication.rb`

```ruby
session[:return_to_after_authenticating] = url_from(request.url) || root_url
# No comment explaining the security purpose
```

## Proposed Solutions
### Option A — Add an inline comment
```ruby
# url_from validates the URL is same-origin (prevents open redirect).
# Falls back to root_url if url_from returns nil (e.g., external host).
session[:return_to_after_authenticating] = url_from(request.url) || root_url
```
**Effort:** Trivial.

## Recommended Action

## Technical Details
- **File:** `app/controllers/concerns/authentication.rb`
- **Context:** `request_authentication` method — sets return-to URL before redirecting to sign-in

## Acceptance Criteria
- [ ] Inline comment explains that url_from prevents open redirect and why root_url is the fallback

## Work Log
- 2026-03-12: Code review finding — security-sentinel

## Resources
- Branch: dev
- Related: todo 215-complete-p1-open-redirect-fix
