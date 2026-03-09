---
status: pending
priority: p2
issue_id: "119"
tags: [code-review, rails, views, quality, profiles]
dependencies: []
---

# `_password_form.html.erb` uses `Current.user` directly instead of the passed `user` local

## Problem Statement

`profiles/show.html.erb` renders `_password_form` with `render "password_form", user: Current.user`. The other profile partials (`_avatar_form`, `_personal_details_form`) use the `user` local variable throughout. `_password_form.html.erb` ignores the passed local and references `Current.user` directly, making the partial tightly coupled to the global `Current` model and untestable in isolation.

## Findings

- `app/views/profiles/_password_form.html.erb:1` — `form_with model: Current.user, url: profile_path`
- `app/views/profiles/_password_form.html.erb:2-4` — `Current.user.errors.any?`, `Current.user.errors.select`
- `app/views/profiles/_avatar_form.html.erb:1` — `form_with model: user, ...` — correct
- `app/views/profiles/_personal_details_form.html.erb:1` — `form_with model: user, ...` — correct

## Proposed Solutions

### Option A: Replace Current.user with user local (Recommended)
```erb
<%= form_with model: user, url: profile_path, method: :patch, class: "profile-password-form" do |form| %>
  <% if user.errors.any? && user.errors.any? { |e| ... } %>
    ...
        <% user.errors.select { ... }.each do |error| %>
```
**Effort:** Small | **Risk:** Low

## Recommended Action

Option A.

## Technical Details

- **Affected file:** `app/views/profiles/_password_form.html.erb`

## Acceptance Criteria

- [ ] All `Current.user` references in `_password_form.html.erb` replaced with `user` local
- [ ] Partial renders identically — no visual change

## Work Log

- 2026-03-08: Identified by pattern-recognition-specialist during PR review
