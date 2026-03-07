---
status: pending
priority: p3
issue_id: "017"
tags: [code-review, performance, turbo, assets]
dependencies: []
---

# `javascript_importmap_tags` Missing `data-turbo-track: "reload"`

## Problem Statement

`app/views/layouts/application.html.erb` adds `data-turbo-track: "reload"` to the stylesheet but not to `javascript_importmap_tags`. During a Turbo Drive navigation (not a full page load), a changed importmap after a deploy will not trigger a page reload — users may run stale JS until they manually refresh. The stylesheet correctly uses turbo-track; the importmap should too.

## Findings

**Flagged by:** performance-oracle

**Location:** `app/views/layouts/application.html.erb`

```erb
<%= stylesheet_link_tag :app, "data-turbo-track": "reload" %>  <!-- correct -->
<%= javascript_importmap_tags %>                                 <!-- missing turbo-track -->
```

## Proposed Solutions

### Option A — Add `data` option to importmap tags
```erb
<%= javascript_importmap_tags "application", data: { turbo_track: "reload" } %>
```

**Effort:** Trivial
**Risk:** None

## Recommended Action

Add it.

## Technical Details

**Acceptance Criteria:**
- [ ] `javascript_importmap_tags` includes `data: { turbo_track: "reload" }`
- [ ] App loads correctly in development and tests pass

## Work Log

- 2026-03-06: Identified by performance-oracle.
