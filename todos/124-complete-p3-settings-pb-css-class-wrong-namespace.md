---
status: pending
priority: p3
issue_id: "124"
tags: [code-review, css, quality, profiles, naming]
dependencies: []
---

# CSS classes `settings-pb-date` and `settings-pb-unset` used in profiles view — wrong namespace

## Problem Statement

After migrating personal best display from settings to the profile page, two CSS classes named `settings-pb-*` are now rendered in `profiles/show.html.erb`. The classes are defined in `settings.css` but applied in a profiles view. This breaks the naming convention and makes the code harder to navigate.

## Findings

- `app/views/profiles/show.html.erb:25` — `class="settings-pb-date"`
- `app/views/profiles/show.html.erb:28` — `class="settings-pb-unset"`
- `app/assets/stylesheets/settings.css:2-3` — definitions live in `settings.css`

## Proposed Solutions

### Option A: Rename and move (Recommended)
1. Add to `profile.css`:
   ```css
   .profile-pb-unset { color: #9ca3af; }
   .profile-pb-date  { color: #9ca3af; font-size: 0.875rem; margin-left: 0.35rem; }
   ```
2. Update `profiles/show.html.erb` to use `profile-pb-*` class names
3. Remove `settings-pb-*` from `settings.css` (or keep as alias if settings view still renders — but it redirects now)

**Effort:** Trivial | **Risk:** Low

## Recommended Action

Option A.

## Technical Details

- **Affected files:** `app/views/profiles/show.html.erb`, `app/assets/stylesheets/settings.css`, `app/assets/stylesheets/profile.css`

## Acceptance Criteria

- [ ] CSS classes in profiles view use `profile-` namespace
- [ ] Classes defined in `profile.css`

## Work Log

- 2026-03-08: Identified by pattern-recognition-specialist during PR review
