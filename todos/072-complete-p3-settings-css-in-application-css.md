---
status: pending
priority: p3
issue_id: "072"
tags: [code-review, css, quality]
dependencies: []
---

# Settings-Specific CSS Lives in `application.css` Instead of `settings.css`

## Problem Statement

The codebase uses a feature-per-file CSS convention (`symptom_timeline.css`, `peak_flow.css`). Settings-specific classes were appended to `application.css` instead of a separate `settings.css`. This is inconsistent with the established pattern and adds feature-specific selectors to the global manifest.

## Findings

**Flagged by:** pattern-recognition-specialist

**Location:** `app/assets/stylesheets/application.css:12-17`

```css
/* Settings page */
.settings-pb-unset { color: #888; font-style: italic; }
.settings-pb-date  { color: #888; font-size: 0.85rem; margin-left: 0.25rem; }
.input-with-unit   { display: flex; align-items: center; gap: 0.5rem; }
.input-unit        { font-size: 0.9rem; color: #666; white-space: nowrap; }
.field-hint        { font-size: 0.8rem; color: #888; margin-top: 0.25rem; }
```

`application.css` itself says: *"Consider organizing styles into separate files for maintainability."*

Peak flow and symptom timeline both have dedicated CSS files. Settings does not.

## Proposed Solution

1. Create `app/assets/stylesheets/settings.css` with the five settings classes
2. Remove them from `application.css`
3. Add `<%= stylesheet_link_tag "settings" %>` to the settings layout or the `<head>` in `application.html.erb`

Note on Propshaft: Propshaft does not auto-link CSS files — explicit `stylesheet_link_tag` is required. The safest approach is to add it to the main layout alongside `peak_flow.css` if that's also globally linked, or to a `content_for :head` block in `settings/show.html.erb`.

**Effort:** Small
**Risk:** Low (verify stylesheet_link_tag placement)

## Acceptance Criteria

- [ ] `settings.css` created with the five settings-specific classes
- [ ] Classes removed from `application.css`
- [ ] `stylesheet_link_tag "settings"` added in the appropriate layout location
- [ ] Settings page renders correctly with styles applied

## Work Log

- 2026-03-07: Identified by pattern-recognition-specialist during Phase 6 code review
