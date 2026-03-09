---
status: pending
priority: p1
issue_id: "106"
tags: [code-review, css, propshaft, rails, ui-bug]
dependencies: []
---

# `profile.css` and `charts.css` not linked in layout — pages render without styling

## Problem Statement

Two new CSS files (`profile.css` and `charts.css`) were created but never linked in `app/views/layouts/application.html.erb`. Propshaft does **not** auto-link CSS files — unlike Sprockets, it does not have a manifest-based `require_tree` mechanism. Every stylesheet must be explicitly referenced via `stylesheet_link_tag` in the layout or a view. The profile page and chart sections have zero custom styling.

## Findings

- `app/assets/stylesheets/profile.css` — exists, not linked
- `app/assets/stylesheets/charts.css` — exists, not linked
- `app/views/layouts/application.html.erb` — only links `application`, `lexxy`, `symptom_timeline`, `settings`, `peak_flow` stylesheets
- Known pattern documented in `docs/solutions/ui-bugs/lexxy-editor-css-missing-from-layout.md` — identical root cause (learnings-researcher finding)

## Proposed Solutions

### Option A: Add to layout head (Recommended)
Add two `stylesheet_link_tag` calls in `<head>` of `application.html.erb` alongside existing ones:
```erb
<%= stylesheet_link_tag "profile" %>
<%= stylesheet_link_tag "charts" %>
```
**Pros:** Consistent with existing pattern. Immediate fix.
**Cons:** Loads both stylesheets on every page (minor overhead).
**Effort:** Small | **Risk:** Low

### Option B: Yield per-page stylesheets
Use `content_for :head` in the profile view and chart views to load per-page.
```erb
<% content_for :head do %>
  <%= stylesheet_link_tag "profile" %>
<% end %>
```
**Pros:** Only loads CSS where needed.
**Cons:** Must add to every view that uses these styles; easy to miss.
**Effort:** Small | **Risk:** Low

## Recommended Action

Option A — add both to the layout. Simplest and consistent with how all other stylesheets are loaded.

## Technical Details

- **Affected files:** `app/views/layouts/application.html.erb`
- **Related pattern:** `docs/solutions/ui-bugs/lexxy-editor-css-missing-from-layout.md`

## Acceptance Criteria

- [ ] `stylesheet_link_tag "profile"` present in `application.html.erb`
- [ ] `stylesheet_link_tag "charts"` present in `application.html.erb`
- [ ] Profile page renders with card layout and avatar styles
- [ ] Chart sections render with `.chart-section` background and border

## Work Log

- 2026-03-08: Identified by learnings-researcher and code-simplicity-reviewer during PR review
