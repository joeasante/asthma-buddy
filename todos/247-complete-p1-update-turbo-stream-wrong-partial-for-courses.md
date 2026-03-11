---
status: pending
priority: p1
issue_id: "247"
tags: [code-review, hotwire, turbo-stream, rails, bug]
dependencies: []
---

# `update.turbo_stream.erb` Always Renders Wrong Partial for Course Medications

## Problem Statement

Editing a course medication and saving it silently replaces the course row in the DOM with a regular medication card. The course badge, end-date display, and course-specific styles all disappear until the user refreshes the page. This is a real regression introduced by Phase 18.

## Findings

`app/views/settings/medications/update.turbo_stream.erb` (line 2) hardcodes `_medication` regardless of `@medication.course?`:

```erb
<%= turbo_stream.replace dom_id(@medication), partial: "settings/medications/medication", locals: { medication: @medication } %>
```

`create.turbo_stream.erb` correctly branches on `@medication.course?` to select the right partial, but `update.turbo_stream.erb` was never updated to match. The result: any PATCH to `/settings/medications/:id` for a course medication renders the regular card and overwrites the course card in the DOM.

Confirmed by: kieran-rails-reviewer, architecture-strategist, code-simplicity-reviewer.

## Proposed Solutions

### Option A — Inline branch (matches create.turbo_stream.erb pattern) *(Recommended)*

```erb
<%= turbo_stream.replace dom_id(@medication) do %>
  <% if @medication.course? %>
    <%= render "settings/medications/course_medication", medication: @medication %>
  <% else %>
    <%= render "settings/medications/medication", medication: @medication %>
  <% end %>
<% end %>

<%= turbo_stream.replace "flash-messages" do %>
  <div id="flash-messages" data-controller="toast"
       data-toast-message="<%= @medication.name %> updated."
       data-toast-variant="success"></div>
<% end %>
```

Pros: consistent with create stream, minimal change, easy to verify
Cons: same dispatch duplication as create stream (addressed separately in #252)

### Option B — Extract helper first, then fix update stream

Add `medication_partial(medication)` helper (#252), then:

```erb
<%= turbo_stream.replace dom_id(@medication) do %>
  <%= render medication_partial(@medication), medication: @medication %>
<% end %>
```

Pros: eliminates all dispatch duplication at once
Cons: requires #252 to be done first; slightly larger scope

## Recommended Action

Option A immediately — ship the fix now, then do Option B as part of #252 cleanup.

## Technical Details

- **Affected file:** `app/views/settings/medications/update.turbo_stream.erb`
- **Related todo:** #252 (medication_partial helper extraction)

## Acceptance Criteria

- [ ] Editing a course medication and saving renders `_course_medication` partial in the Turbo Stream response
- [ ] Editing a non-course medication and saving still renders `_medication` partial
- [ ] Controller test added: `PATCH /settings/medications/:id` for a course medication asserts `medication-badge--course` in response body
- [ ] Controller test added: `PATCH /settings/medications/:id` for a non-course medication asserts no `medication-badge--course`

## Work Log

- 2026-03-10: Found by Phase 18 code review (kieran-rails-reviewer, architecture-strategist, code-simplicity-reviewer)
