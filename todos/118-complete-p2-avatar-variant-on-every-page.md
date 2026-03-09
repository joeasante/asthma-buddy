---
status: pending
priority: p2
issue_id: "118"
tags: [code-review, performance, active-storage, avatar, rails]
dependencies: []
---

# Avatar variant computed on every page render — N+1 against Active Storage

## Problem Statement

The nav dropdown in `application.html.erb` calls `Current.user.avatar.variant(resize_to_fill: [36, 36])` on every page render for every authenticated user. Active Storage variant processing involves: (1) checking if the variant exists in blob storage, (2) processing it with ImageMagick if not, (3) generating a signed URL. This is at minimum a DB query per request plus a potential network round-trip to blob storage. For the most-rendered partial in the app (the navigation), this is significant.

## Findings

- `app/views/layouts/application.html.erb` — `Current.user.avatar.variant(resize_to_fill: [36, 36])` in nav dropdown
- `User::AVATAR_NAV_VARIANT = { resize_to_fill: [36, 36] }` defined in model but variant still processed on every render
- No fragment caching on the nav avatar
- Performance Oracle flagged this as a P2 issue

## Proposed Solutions

### Option A: Preprocess variant on avatar upload (Recommended)
In `ProfilesController#update`, after saving the avatar, call `Current.user.avatar.variant(User::AVATAR_NAV_VARIANT).processed` to ensure the variant is pre-computed and cached. Subsequent renders will find the variant already processed.

**Pros:** Variant processed once at upload time, not on every render.
**Cons:** Adds processing time to the upload request.
**Effort:** Small | **Risk:** Low

### Option B: Fragment cache the nav avatar
Wrap the nav avatar HTML in a `cache` block keyed on the user's `updated_at`:
```erb
<% cache ["nav-avatar", Current.user] do %>
  <%# avatar img or initials span %>
<% end %>
```
**Pros:** Zero overhead for repeat visits.
**Cons:** Requires cache invalidation strategy; adds caching complexity.
**Effort:** Small | **Risk:** Low

## Recommended Action

Option A as an immediate improvement, Option B for high-traffic scenarios.

## Technical Details

- **Affected files:** `app/controllers/profiles_controller.rb` (preprocess on upload), `app/views/layouts/application.html.erb`

## Acceptance Criteria

- [ ] Avatar variant is pre-processed on upload (not lazily on each render)
- [ ] Nav renders without Active Storage variant computation on repeat page loads

## Work Log

- 2026-03-08: Identified by performance-oracle during PR review
