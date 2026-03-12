---
title: "Turbo Frame 'Content Missing' when navigating from list to show page"
slug: turbo-frame-content-missing-full-page-navigation
category: ui-bugs
tags: [turbo-frames, navigation, content-missing, turbo_frame_top, link_to, hotwire]
symptom: "Clicking a list item shows Turbo's own 'Content Missing' error inside the page instead of navigating to the show page"
component: turbo_frame_tag / link_to
framework: Rails 8.1.2 / Hotwire Turbo
related:
  - ui-bugs/turbo-frame-top-blocks-stream-edit-in-place.md
  - ui-bugs/turbo-hotwire-dom-targeting-and-frame-rendering.md
---

# Turbo Frame 'Content Missing' when navigating from list to show page

## Symptom

Clicking a list item in a filtered/paginated index view appears to do nothing — the page stays the same but the list area is replaced with Turbo's generic "Content Missing" message. The URL does not change. The page header and surrounding chrome are still visible; only the framed content area changes.

```
History
content missing          ← Turbo's own error, not yours
```

## Root Cause

When a page wraps its content in a named `turbo_frame_tag`, every `link_to` inside that frame is silently intercepted by Turbo. Turbo fetches the linked page and looks for a `<turbo-frame id="…">` element with the **same id** in the response. If the destination page has no matching frame, Turbo renders its own "Content Missing" error inside the frame instead of performing a full-page navigation.

In this case:

- `index.html.erb` wraps the list in `turbo_frame_tag "timeline_content"`
- `_timeline_row.html.erb` renders `link_to symptom_log_path(symptom_log)` inside that frame
- `show.html.erb` has no `<turbo-frame id="timeline_content">` element
- Result: Turbo cannot splice the frame and falls back to "Content Missing"

The frame is a scope boundary. Links inside it inherit that scope unless explicitly told to break out.

## Fix

Add `data: { turbo_frame: "_top" }` to any link inside the frame that should perform full-page navigation:

```erb
<%# app/views/symptom_logs/_timeline_row.html.erb — BEFORE %>
<%= link_to symptom_log_path(symptom_log),
      id: dom_id(symptom_log),
      class: "timeline-card",
      aria: { label: "…" } do %>

<%# AFTER %>
<%= link_to symptom_log_path(symptom_log),
      id: dom_id(symptom_log),
      class: "timeline-card",
      data: { turbo_frame: "_top" },
      aria: { label: "…" } do %>
```

`"_top"` is a Turbo reserved keyword (mirrors HTML `target="_top"`) that instructs Turbo to break out of all enclosing frames and perform a full-page navigation.

## Why `_top` Works

`data-turbo-frame="_top"` overrides the inherited frame scope for that specific link. The click triggers a standard full-page Turbo Drive navigation — the entire `<body>` is replaced with the show page response — rather than Turbo attempting a scoped frame splice.

## Alternative (Not Recommended)

Wrapping `show.html.erb`'s content in `turbo_frame_tag "timeline_content"` would also fix the Content Missing error. But this couples the show page's DOM structure to the index page's frame layout, breaks direct show-page navigation (visiting `/symptom-logs/123` directly would render inside a bare frame without the surrounding layout), and is architecturally backward — the show page should not know it was navigated to from a frame.

## Prevention

**Code review red flags:**

- `turbo_frame_tag "name"` wrapping a collection with `link_to` calls pointing to show/edit/new routes, and no `data: { turbo_frame: … }` on those links
- A partial rendered inside a named frame that contains navigation links — frame context is inherited by partials
- A show or edit template with no `turbo_frame_tag` matching a frame on any page that links to it
- `button_to` inside a frame with `method: :get` — same trap

**Rule of thumb:** "Frame in, frame out — or declare your exit."

A named turbo frame is a cage. Every link inside tries to swap content within the cage. If the destination page has no matching cage, Turbo shows "Content Missing". Any link that intentionally leaves the cage must carry `data: { turbo_frame: "_top" }`.

## Known Patterns in This Codebase

The following views correctly apply `data: { turbo_frame: "_top" }` on card links inside frames:

- `app/views/peak_flow_readings/_reading_card.html.erb` — link to show page breaks out of `readings_content` frame
- `app/views/settings/medications/_medication.html.erb` — Edit link breaks out of the `dom_id(medication)` frame
- `app/views/settings/medications/_course_medication.html.erb` — same pattern

## Watch For

The inverse bug is documented in [`turbo-frame-top-blocks-stream-edit-in-place.md`](turbo-frame-top-blocks-stream-edit-in-place.md): placing `data: { turbo_frame: "_top" }` on a **form** (not a link) breaks Turbo Stream responses for in-place editing, because `_top` strips the `text/vnd.turbo-stream.html` accept header from the request.

> `data: { turbo_frame: "_top" }` is safe on `link_to`; it can be problematic on `form_with` when you need Turbo Stream responses.
