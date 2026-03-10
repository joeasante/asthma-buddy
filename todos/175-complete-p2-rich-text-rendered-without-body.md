---
status: pending
priority: p2
issue_id: "175"
tags: [code-review, action-text, views, show-pages]
dependencies: []
---

# Rich Text Notes Rendered as ActionText Proxy Object, Not .body

## Problem Statement
symptom_logs/show.html.erb line 46: `<%= @symptom_log.notes %>` and health_events/show.html.erb line 70: `<%= @health_event.notes %>`. Both render the ActionText::RichText association proxy object directly. This works because ActionText defines to_s to delegate to the body, but: (1) it is inconsistent with the explicit `.body.present?` check two lines above each render; (2) it depends on undocumented ActionText internal behaviour; (3) the presence check calls `.body.present?` but the render calls `to_s` on the proxy — these could diverge in a future ActionText version.

## Proposed Solutions

### Option A
Use `<%= @symptom_log.notes.body %>` and `<%= @health_event.notes.body %>` for explicit, idiomatic ActionText rendering. This matches the `.body.present?` pattern already used for the guard check.
- Effort: Small
- Risk: Low

## Recommended Action

## Technical Details
- Affected files: app/views/symptom_logs/show.html.erb, app/views/health_events/show.html.erb

## Acceptance Criteria
- [ ] symptom_logs/show.html.erb renders notes via `.body` explicitly
- [ ] health_events/show.html.erb renders notes via `.body` explicitly
- [ ] Both views use the same pattern for the presence guard and the render
- [ ] Rich text content still renders correctly in the browser after the change

## Work Log
- 2026-03-10: Created via code review
