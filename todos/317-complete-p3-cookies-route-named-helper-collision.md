---
status: complete
priority: p3
issue_id: 317
tags: [code-review, routing, naming, maintainability]
---

# 317 — P3 — cookies_path named helper shadows Rails cookies accessor in mental model

## Problem Statement

`config/routes.rb` line 68 defines:

```ruby
get "cookies", to: "pages#cookie_policy", as: :cookies
```

The `as: :cookies` option generates the named route helper `cookies_path`. In Rails, `cookies` is a well-known accessor (the `ActionDispatch::Cookies` cookie jar, available in controllers and views). While there is no functional conflict at runtime — `cookies_path` (the route helper) and `cookies` (the accessor) are different method signatures — the naming creates immediate confusion for any developer reading code that uses both:

```erb
<%= link_to "Cookies", cookies_path %>
<%# cookies is also used elsewhere as the cookie jar accessor — cookies[:cookie_notice_dismissed] %>
```

The other two legal page routes — `privacy_path` and `terms_path` — are named after the content, not the Rails built-in concept (`privacy` and `terms` have no Rails accessor shadow). The action itself is called `cookie_policy`, making `cookie_policy_path` the natural, unshadowing name.

## Findings

- `config/routes.rb` line 68: `get "cookies", to: "pages#cookie_policy", as: :cookies`
- Generated helper: `cookies_path` → `/cookies`
- `app/views/layouts/application.html.erb` lines 135 and 144: `<%= link_to "Cookies", cookies_path %>` (appears twice — authenticated footer at line 135, unauthenticated footer at line 144)
- No other callers of `cookies_path` found in the codebase beyond these two footer occurrences
- `cookies` (the Rails accessor) is used in `app/views/layouts/application.html.erb` line 124: `cookies[:cookie_notice_dismissed]`
- The URL segment `/cookies` does not need to change — only the named route alias changes from `cookies` to `cookie_policy`
- After the rename: `cookies_path` is no longer defined; `cookie_policy_path` generates `/cookies`

**Affected files:**
- `config/routes.rb` line 68
- `app/views/layouts/application.html.erb` lines 135 and 144

## Proposed Solutions

### Option A — Rename `as: :cookies` to `as: :cookie_policy` (recommended)

1. In `config/routes.rb`, change:
   ```ruby
   get "cookies", to: "pages#cookie_policy", as: :cookies
   ```
   to:
   ```ruby
   get "cookies", to: "pages#cookie_policy", as: :cookie_policy
   ```

2. In `app/views/layouts/application.html.erb`, update both footer link_to calls:
   ```erb
   <%= link_to "Cookies", cookie_policy_path %>
   ```
   (Replace both occurrences at lines 135 and 144.)

3. Run `bin/rails routes` to confirm `cookie_policy_path` resolves to `/cookies`.

The URL visible to users (`/cookies`) does not change.

### Option B — Leave as-is

Accept the naming as a non-functional quirk. The shadow is in the mental model only — no runtime failure occurs because route helpers are methods with different names from the `cookies` accessor (no actual method collision). Not recommended — this is precisely the kind of subtle naming trap that causes bugs during future refactors.

## Acceptance Criteria

- [ ] `config/routes.rb` uses `as: :cookie_policy` for the cookies route
- [ ] `cookies_path` is no longer defined as a named route helper
- [ ] `cookie_policy_path` generates `/cookies` (confirmed via `bin/rails routes`)
- [ ] Both footer `link_to "Cookies"` calls in `application.html.erb` use `cookie_policy_path`
- [ ] No remaining references to `cookies_path` in views, helpers, or tests
- [ ] Cookie policy page continues to load at `/cookies` (URL unchanged)
- [ ] Existing route and controller tests pass

## Technical Details

| Field | Value |
|---|---|
| Affected files | `config/routes.rb` line 68; `app/views/layouts/application.html.erb` lines 135, 144 |
| Root cause | Named route `as: :cookies` generates `cookies_path`, shadowing the Rails `cookies` accessor in readers' mental model |
| Runtime impact | None — `cookies_path` and `cookies` are different method identifiers; no actual collision |
| Maintainability impact | Confusing for developers reading code that uses both `cookies_path` and `cookies[:key]` in nearby lines |
| Callers of `cookies_path` | `app/views/layouts/application.html.erb` lines 135 and 144 (both footer variants) |
| URL impact | None — the public URL `/cookies` does not change |
| Severity | P3 — naming clarity / maintainability |
| Fix complexity | Low — one route change, two view updates |
