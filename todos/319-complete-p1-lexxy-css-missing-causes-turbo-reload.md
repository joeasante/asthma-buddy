---
status: complete
priority: p1
issue_id: "319"
tags: [code-review, frontend, turbo, assets, bug]
dependencies: []
---

# `stylesheet_link_tag "lexxy"` References Non-Existent CSS File

## Problem Statement

`app/views/layouts/application.html.erb:27` loads `stylesheet_link_tag "lexxy"` but no `lexxy.css` file exists anywhere in the asset pipeline. The Lexxy component styles are embedded directly in `application.css`. Because the tag carries `data-turbo-track: "reload"`, Turbo computes a fingerprint for the asset on every page load. When the asset is missing or its fingerprint changes across pages, Turbo triggers a full-page reload unnecessarily. This is a silent production bug causing degraded navigation performance for authenticated users.

## Findings

**Flagged by:** pattern-recognition-specialist (rated HIGH — must fix before production)

- `app/views/layouts/application.html.erb:27`: `stylesheet_link_tag "lexxy", "data-turbo-track": "reload"`
- No `lexxy.css` file exists in `app/assets/stylesheets/` or any subdirectory
- Lexxy styles are embedded inside `application.css` (confirmed by Propshaft asset manifest)
- The `data-turbo-track: "reload"` attribute on a missing/unstable asset causes Turbo to detect a version mismatch and force full-page reloads — breaking the SPA-like navigation experience

## Proposed Solutions

### Option A: Remove the stale tag (Recommended)
Delete the `stylesheet_link_tag "lexxy"` line from `application.html.erb`. The styles are already in `application.css` and load unconditionally.

**Pros:** One-line fix, eliminates the bug entirely
**Cons:** None
**Effort:** Small
**Risk:** None — removing a broken tag that loads nothing

### Option B: Create a `lexxy.css` file
Extract Lexxy-related styles from `application.css` into `app/assets/stylesheets/lexxy.css`.

**Pros:** Lazy-loads Lexxy styles only for authenticated users
**Cons:** Requires identifying and moving CSS; risks regressions
**Effort:** Medium
**Risk:** Medium — CSS refactor

### Recommended Action

Option A — just remove the broken tag.

## Technical Details

- **File:** `app/views/layouts/application.html.erb:27`
- **Line to remove:** `<%= stylesheet_link_tag "lexxy", "data-turbo-track": "reload" %>`

## Acceptance Criteria

- [ ] `lexxy` stylesheet link tag is removed from the layout
- [ ] No 404 errors for `lexxy.css` in browser network tab
- [ ] Turbo navigation between authenticated pages works without full-page reloads
- [ ] All existing tests pass

## Work Log

- 2026-03-12: Created from Milestone 2 code review — pattern-recognition-specialist finding
