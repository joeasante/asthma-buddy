---
status: complete
priority: p1
issue_id: 307
tags: [code-review, security]
---

# 307 — P1 — `cookie_notice_dismissed` cookie missing HttpOnly, Secure, and SameSite attributes

## Problem Statement

The `cookie_notice_dismissed` cookie set in `CookieNoticesController#dismiss` does not include `httponly: true`, `secure: !Rails.env.local?`, or `same_site: :lax`.

The application's session cookie sets all three of these attributes, establishing a clear security posture for cookies. The `cookie_notice_dismissed` cookie deviates from that posture. Most critically, omitting `httponly: true` means the cookie is accessible via JavaScript — any XSS vector in the application could read or manipulate it.

## Findings

- `CookieNoticesController#dismiss` (line 10) sets the cookie without security attributes
- The session cookie uses `httponly: true`, `secure: !Rails.env.local?`, and `same_site: :lax`
- Missing `httponly: true` — cookie readable by JavaScript; XSS can access it
- Missing `secure: !Rails.env.local?` — cookie transmitted over HTTP in non-local environments
- Missing `same_site: :lax` — cookie sent on cross-site top-level navigations; inconsistent CSRF protection posture

The cookie itself stores only a boolean preference, but inconsistent security attributes across cookies weakens the overall security posture and creates a discoverability risk in security audits.

**Affected file:** `app/controllers/cookie_notices_controller.rb`, line 10

## Proposed Solutions

### Option A — Add all three attributes to the cookie hash (recommended)

Update the `cookies[]` assignment to match the session cookie's attribute set:

```ruby
cookies[:cookie_notice_dismissed] = {
  value: "true",
  expires: 1.year.from_now,
  httponly: true,
  secure: !Rails.env.local?,
  same_site: :lax
}
```

This brings the cookie into full alignment with the session cookie's security posture and requires no architectural changes.

### Option B — Use a signed cookie
Store the preference as a signed cookie (`cookies.signed[:cookie_notice_dismissed]`). This prevents client-side tampering with the value. In practice the value is just `"true"` so tampering has minimal impact, but signed cookies also carry the HttpOnly attribute by default in Rails.

### Option C — Store the preference server-side
Move the dismissed state to the user's session or database record (for authenticated users) rather than a browser cookie. Eliminates client-side cookie concerns entirely. Higher implementation cost; acceptable if a future preference system is planned.

## Acceptance Criteria

- [ ] `cookie_notice_dismissed` cookie is set with `httponly: true`
- [ ] `cookie_notice_dismissed` cookie is set with `secure: !Rails.env.local?` (or equivalent)
- [ ] `cookie_notice_dismissed` cookie is set with `same_site: :lax`
- [ ] Existing cookie banner dismiss behaviour (banner hides, preference persists across page loads) continues to work
- [ ] Test coverage updated to assert the cookie attributes are present

## Technical Details

| Field | Value |
|---|---|
| Affected file | `app/controllers/cookie_notices_controller.rb` line 10 |
| Root cause | Cookie created without `httponly`, `secure`, or `same_site` attributes |
| Failure mode | Cookie readable by JavaScript (XSS risk); transmitted over HTTP; inconsistent CSRF posture |
| Severity | P1 — inconsistent with app security posture; `httponly` absence is the primary concern |
| Comparison | Session cookie correctly sets all three attributes |
