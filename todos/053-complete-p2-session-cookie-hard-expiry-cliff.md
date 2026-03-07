---
status: pending
priority: p2
issue_id: "053"
tags: [code-review, authentication, ux, sessions]
dependencies: []
---

# Session Cookie Has Hard 2-Week Expiry With No Sliding Window — Daily Users Get Surprise Logouts

## Problem Statement

`start_new_session_for` sets a fixed 2-week cookie expiry. `resume_session` never refreshes it. A user who logs in on day 1 and uses the app daily will be silently logged out on day 14 with no warning — they will try to log a symptom and get redirected to the login page. For a health app expected to be used daily, this is a poor UX cliff.

## Findings

**Flagged by:** architecture-strategist (P2), security-sentinel (LOW-02)

**Location:** `app/controllers/concerns/authentication.rb:48-51`

```ruby
cookies.signed[:session_id] = {
  value: session.id, httponly: true, secure: !Rails.env.local?,
  same_site: :lax,
  expires: 2.weeks.from_now  # hard expiry, never refreshed
}
```

`resume_session` only reads the session — it never touches the cookie:

```ruby
def resume_session
  Current.session ||= find_session_by_cookie  # no cookie refresh
end
```

## Proposed Solutions

### Solution A: Sliding expiry — refresh cookie on each authenticated request (Recommended)

```ruby
def resume_session
  Current.session ||= find_session_by_cookie
  refresh_session_cookie if Current.session
end

def refresh_session_cookie
  cookies.signed[:session_id] = {
    value: Current.session.id, httponly: true, secure: !Rails.env.local?,
    same_site: :lax, expires: 2.weeks.from_now
  }
end
```

This extends the cookie expiry on every authenticated page view, so active users are never logged out involuntarily.

- **Effort:** Small
- **Risk:** Low — adds one cookie write per request (negligible overhead)

### Solution B: Warn the user N days before expiry

Check remaining cookie lifetime and flash a notice if < 3 days remain.
- **Effort:** Medium (requires parsing cookie expiry metadata)
- **Risk:** Low but more complex

### Solution C: Keep hard expiry but increase to 90 days

Simple stopgap but doesn't solve the underlying UX issue.
- **Effort:** Tiny
- **Risk:** Very low

## Acceptance Criteria

- [ ] A user who uses the app daily is never involuntarily logged out after 14 days
- [ ] The session expiry is either sliding or long enough that it doesn't surprise regular users
- [ ] The DB-side session record expiry is consistent with the cookie expiry

## Work Log

- 2026-03-07: Created from architecture and security review. architecture-strategist, security-sentinel LOW-02.
