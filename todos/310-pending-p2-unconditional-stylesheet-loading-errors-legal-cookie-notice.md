---
status: pending
priority: p2
issue_id: 310
tags: [code-review, performance, assets]
---

# 310 — P2 — `errors.css`, `legal.css`, and `cookie_notice.css` loaded unconditionally on every page

## Problem Statement

`app/views/layouts/application.html.erb` lines 24–26 include render-blocking `<link>` tags for `cookie_notice.css`, `legal.css`, and `errors.css` on every page in the application. These stylesheets are only needed by a small subset of views (error pages, legal pages, and the cookie notice banner respectively), yet they are loaded unconditionally on the dashboard, symptom log, peak flow readings, settings — every page a logged-in user visits.

Each tag is a render-blocking request: the browser must fetch and parse the stylesheet before it can render the page. At scale (1,000 DAU × ~20 page loads/day) this generates approximately 60,000 unnecessary HTTP requests per day, delays First Contentful Paint for authenticated users, and inflates both server bandwidth and CDN egress costs.

The rest of the authenticated stylesheet block (lines 28–40) already demonstrates the correct pattern — stylesheets are conditionally loaded inside `<% if authenticated? %>`. The three affected stylesheets were placed outside that guard and have never been moved.

## Findings

- `app/views/layouts/application.html.erb` line 24: `stylesheet_link_tag "cookie_notice"` — unconditional
- `app/views/layouts/application.html.erb` line 25: `stylesheet_link_tag "legal"` — unconditional
- `app/views/layouts/application.html.erb` line 26: `stylesheet_link_tag "errors"` — unconditional
- All three tags carry `"data-turbo-track": "reload"`, meaning Turbo treats a change to any of these files as a full page reload trigger — an additional minor correctness issue for files rarely changed
- `cookie_notice.css` is used only by `app/views/layouts/_cookie_notice.html.erb`, which is already conditionally rendered (`unless authenticated? || cookies[:cookie_notice_dismissed].present?`)
- `legal.css` is used only by views in `app/views/pages/` (cookie policy, privacy, terms)
- `errors.css` is used only by views in `app/views/errors/`
- The authenticated stylesheet block (lines 28–40) already uses `content_for`-style conditional loading as a precedent

**Affected files:**
- `app/views/layouts/application.html.erb` (lines 24–26)
- `app/views/errors/*.html.erb`
- `app/views/pages/cookie_policy.html.erb`, `privacy.html.erb`, `terms.html.erb`
- `app/views/layouts/_cookie_notice.html.erb`

## Proposed Solutions

### Option A — Move stylesheets to `content_for :head` in the consuming views (recommended)

Remove lines 24–26 from `application.html.erb`. In each consuming view (or partial), add:

```erb
<% content_for :head do %>
  <%= stylesheet_link_tag "errors", "data-turbo-track": "reload" %>
<% end %>
```

Ensure `application.html.erb` renders the `head` yield: `<%= yield :head %>` inside `<head>`. This is the standard Rails pattern for view-specific assets.

For `cookie_notice.css`, add the `content_for` block inside `app/views/layouts/_cookie_notice.html.erb` directly, so the stylesheet travels with the partial rather than being spread across multiple files.

### Option B — Consolidate all three into `application.css`

Append the contents of `errors.css`, `legal.css`, and `cookie_notice.css` into `application.css`. Eliminates three HTTP requests entirely at the cost of a slightly larger `application.css`. Acceptable if the total size increase is under ~10 KB. Requires no per-view changes.

### Option C — Wrap in a controller-name check in the layout

```erb
<%= stylesheet_link_tag "errors" if controller_name == "errors" %>
<%= stylesheet_link_tag "legal" if controller_name == "pages" %>
<%= stylesheet_link_tag "cookie_notice" unless authenticated? || cookies[:cookie_notice_dismissed].present? %>
```

Quick to implement; keeps logic in the layout file. Less clean than option A (controller coupling in the layout) but avoids adding `content_for` blocks to every view.

## Acceptance Criteria

- [ ] `errors.css` is not loaded on authenticated pages (dashboard, symptom log, etc.)
- [ ] `legal.css` is not loaded on authenticated pages or error pages
- [ ] `cookie_notice.css` is not loaded on pages where the cookie notice is never rendered (authenticated sessions, after cookie dismissed)
- [ ] Error pages continue to render with correct styles
- [ ] Legal pages continue to render with correct styles
- [ ] Cookie notice banner continues to render with correct styles when shown
- [ ] No render-blocking stylesheet requests are added back as a side-effect

## Technical Details

| Field | Value |
|---|---|
| Affected file | `app/views/layouts/application.html.erb` lines 24–26 |
| Root cause | Stylesheets for narrow-use views placed outside the conditional authenticated block |
| Performance impact | ~3 extra render-blocking HTTP requests per page load; ~60,000 unnecessary requests/day at 1,000 DAU × 20 page loads |
| Severity | P2 — measurable performance regression on every page load for all users |
| Turbo side-effect | `data-turbo-track: reload` on infrequently-changed files triggers full reloads unnecessarily |
| Fix complexity | Low — move three `stylesheet_link_tag` calls to consuming views using `content_for :head` |
