---
status: pending
priority: p3
issue_id: "234"
tags: [code-review, gdpr, legal, rails]
dependencies: []
---

# Cookie notice session flag cleared on logout — banner reappears on every login (product decision needed)

## Problem Statement

`session[:cookie_notice_shown]` is stored in the Rails session (Rack cookie store). When the user logs out (`terminate_session`), the session is cleared. On next login, the session is fresh — `cookie_notice_shown` is `nil` — and the banner reappears. Whether this is correct depends on a product/legal decision: is the cookie notice informational (no consent required under PECR for strictly necessary cookies — reappearing is a minor nuisance) or is it consent-gating (should persist across sessions — requires a permanent cookie)?

## Findings

**Flagged by:** phase-16-code-reviewer

**Location:** `app/controllers/cookie_notices_controller.rb`, `app/controllers/application_controller.rb`

## Proposed Solutions

### Option A — Keep current behaviour (session-scoped, reappears on login)

Acceptable if the notice is purely informational (e.g. "this site uses strictly necessary cookies only"). No code change needed. Add a comment to `CookieNoticesController#dismiss` documenting the intent:

```ruby
# Cookie notice is session-scoped. It reappears after logout because
# terminate_session clears the session. This is acceptable for an
# informational notice covering strictly necessary cookies (PECR-compliant).
# If consent persistence across sessions is required, switch to Option B.
session[:cookie_notice_shown] = true
```

**Effort:** Trivial — comment only
**Risk:** None

### Option B — Persist across sessions (permanent cookie)

Change `CookieNoticesController#dismiss` to set a permanent cookie instead of a session key:

```ruby
cookies.permanent[:cookie_notice_shown] = true
```

Update `set_cookie_notice_flag` (or the layout check, per todo 230) to read from `cookies[:cookie_notice_shown]` instead of `session[:cookie_notice_shown]`:

```ruby
# In ApplicationController (or inlined in layout):
@show_cookie_notice = !cookies[:cookie_notice_shown]
```

**Effort:** Low — two files, two lines changed
**Risk:** Low — existing sessions will reshow the banner once on next visit (one-time nuisance)

## Recommended Action

This is a product/legal decision first. If strictly necessary cookies only — Option A with comment is sufficient. If the banner serves as a consent mechanism — Option B.

## Technical Details

**Acceptance Criteria:**
- [ ] Product/legal decision documented in a comment
- [ ] If permanent: cookie notice does not reappear after logout/login

## Work Log

- 2026-03-10: Identified by phase-16-code-reviewer.
