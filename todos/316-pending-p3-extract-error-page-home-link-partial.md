---
status: pending
priority: p3
issue_id: 316
tags: [code-review, dry, views, error-handling]
---

# 316 — P3 — Duplicate home-link block across error views — extract to partial

## Problem Statement

The recovery `link_to` block in `app/views/errors/not_found.html.erb` (lines 10–12) and `app/views/errors/internal_server_error.html.erb` (lines 12–14) is character-for-character identical. Both views render a primary action button that sends authenticated users to `dashboard_path` and unauthenticated users to `root_path`, with matching button text and CSS class. This is a DRY violation: if the link text, path logic, CSS class, or `authenticated?` branching ever changes, the edit must be made in two places, with the risk of the two views diverging silently.

```erb
<%= link_to authenticated? ? dashboard_path : root_path, class: "btn-primary" do %>
  <%= authenticated? ? "Go to dashboard" : "Go to home page" %>
<% end %>
```

## Findings

- `app/views/errors/not_found.html.erb` lines 10–12: the `link_to` block above
- `app/views/errors/internal_server_error.html.erb` lines 12–14: identical `link_to` block
- Both views live in `app/views/errors/` — an `_home_link.html.erb` partial in the same directory is the natural Rails convention
- The partial would call `authenticated?` directly (the helper is available in all views via `ApplicationHelper` / `ApplicationController`)
- No locals are needed — the partial has no parameters
- The partial would be rendered with `<%= render "errors/home_link" %>` in each view

**Affected files:**
- `app/views/errors/not_found.html.erb` lines 10–12
- `app/views/errors/internal_server_error.html.erb` lines 12–14

## Proposed Solutions

### Option A — Extract to `app/views/errors/_home_link.html.erb` (recommended)

1. Create `app/views/errors/_home_link.html.erb` with the shared `link_to` block:

```erb
<%= link_to authenticated? ? dashboard_path : root_path, class: "btn-primary" do %>
  <%= authenticated? ? "Go to dashboard" : "Go to home page" %>
<% end %>
```

2. In `not_found.html.erb`, replace lines 10–12 with:

```erb
<%= render "errors/home_link" %>
```

3. In `internal_server_error.html.erb`, replace lines 12–14 with:

```erb
<%= render "errors/home_link" %>
```

### Option B — Helper method

Define a `error_home_link` helper in `ApplicationHelper` that returns the `link_to` tag. Less conventional for view-level output — partials are the Rails idiom here.

## Acceptance Criteria

- [ ] `app/views/errors/_home_link.html.erb` exists and contains the shared `link_to` block
- [ ] `app/views/errors/not_found.html.erb` renders the partial in place of the inline `link_to` block
- [ ] `app/views/errors/internal_server_error.html.erb` renders the partial in place of the inline `link_to` block
- [ ] Authenticated users visiting `/404` or `/500` still see "Go to dashboard" linking to `dashboard_path`
- [ ] Unauthenticated users visiting `/404` or `/500` still see "Go to home page" linking to `root_path`
- [ ] Existing error page tests pass; add/update tests to assert the link target and text for both auth states on both pages

## Technical Details

| Field | Value |
|---|---|
| Affected files | `app/views/errors/not_found.html.erb` lines 10–12; `app/views/errors/internal_server_error.html.erb` lines 12–14 |
| Root cause | DRY violation — identical 3-line `link_to` block duplicated across two error views |
| Risk if not addressed | Link text, path, or class change must be applied in two places; views may diverge |
| Severity | P3 — maintainability |
| Fix complexity | Low — create one partial file, replace two inline blocks |
| Rails convention | Partials in `app/views/errors/` prefixed with `_` are the standard Rails approach |
