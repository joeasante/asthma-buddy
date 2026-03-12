---
status: complete
priority: p2
issue_id: 313
tags: [code-review, ux, error-handling, cookie-notice]
---

# 313 — P2 — Cookie notice banner renders on 404 and 500 error pages

## Problem Statement

The cookie notice banner is rendered for any unauthenticated user who has not yet dismissed it. The current condition in `application.html.erb` line 124 is:

```erb
<%= render "layouts/cookie_notice" unless authenticated? || cookies[:cookie_notice_dismissed].present? %>
```

This condition does not exclude error pages. An unauthenticated user who lands on a 404 or 500 error page will see both the error message and the cookie notice banner at the same time. On a 500 page triggered by a database outage, the banner's dismiss action (a POST to `cookie-notice/dismiss`) will itself fail — the user clicks "Dismiss" and receives another error. This creates a confusing compound failure state.

The error pages exist to communicate a clear, actionable message. Rendering a cookie banner on top of them dilutes that message and adds unnecessary complexity to a page that must remain functional even under degraded conditions.

## Findings

- `app/views/layouts/application.html.erb` line 124: cookie notice rendered `unless authenticated? || cookies[:cookie_notice_dismissed].present?`
- No check for `controller_name` — the banner renders on error pages for unauthenticated first-time visitors
- `app/views/errors/not_found.html.erb` and `app/views/errors/internal_server_error.html.erb` are served via `ErrorsController` which inherits from `ApplicationController` (see also Todo 306), so the layout runs normally including the cookie notice partial
- The cookie notice dismiss action is `CookieNoticesController#dismiss` (a POST request); during a database outage this POST will itself fail, meaning the user cannot dismiss the banner on the very page that exists to report the outage
- The `ErrorsController` is also accessible for authenticated users who have dismissed the cookie — no impact there — but unauthenticated users (including new visitors who hit a 404) will always see both the error and the banner
- `controller_name` returns `"errors"` for all actions in `ErrorsController`

**Affected file:** `app/views/layouts/application.html.erb` line 124

## Proposed Solutions

### Option A — Add `controller_name == "errors"` guard (recommended)

```erb
<%= render "layouts/cookie_notice" unless authenticated? || cookies[:cookie_notice_dismissed].present? || controller_name == "errors" %>
```

One-character surgical change. The cookie notice is suppressed on all error pages regardless of authentication state or dismiss status. No impact on any other page.

### Option B — Use `content_for` to opt pages into the cookie notice

Remove the unconditional render from the layout. In every non-error view that should show the cookie notice, use `content_for :cookie_notice` to signal opt-in. The layout renders the notice only if the content region was set. This is the most architecturally correct approach but requires touching every non-error view (or adding the `content_for` call to a shared partial).

### Option C — Check against a list of excluded controller names

If future controllers should also suppress the banner (e.g. a maintenance controller), extend the guard to a list:

```erb
<% excluded = %w[errors] %>
<%= render "layouts/cookie_notice" unless authenticated? || cookies[:cookie_notice_dismissed].present? || excluded.include?(controller_name) %>
```

Same immediate effect as option A, slightly more extensible.

## Acceptance Criteria

- [ ] The cookie notice banner does NOT render on `errors#not_found` (404 pages)
- [ ] The cookie notice banner does NOT render on `errors#internal_server_error` (500 pages)
- [ ] The cookie notice banner continues to render normally on all other unauthenticated pages (legal pages, login page, etc.) for users who have not dismissed it
- [ ] The cookie notice banner continues to NOT render for authenticated users and users who have dismissed it (existing behaviour preserved)
- [ ] No test regressions; add test asserting banner is absent on error pages

## Technical Details

| Field | Value |
|---|---|
| Affected file | `app/views/layouts/application.html.erb` line 124 |
| Root cause | Cookie notice render condition does not exclude error pages |
| Failure mode (500 + DB outage) | Cookie banner renders; user clicks Dismiss; POST to `cookie-notice/dismiss` fails; user sees second error |
| UX impact | Error page message is diluted by an unrelated UI element; dismiss action fails during outages |
| Severity | P2 — poor UX on error pages; dismiss failure creates confusing compound error state during outages |
| Fix complexity | Trivial — one additional condition on an existing `unless` clause |
| Related issues | Todo 306 (`ErrorsController` inherits `ApplicationController`), Todo 308 (DB query on 500 view) |
