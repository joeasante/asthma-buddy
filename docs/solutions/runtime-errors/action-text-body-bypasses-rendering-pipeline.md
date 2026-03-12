---
title: "ActionText .body bypasses rendering pipeline — 'content missing' for attachments"
slug: action-text-body-bypasses-rendering-pipeline
category: runtime-errors
tags: [actiontext, rich-text, activestorage, attachments, rendering, has_rich_text]
symptom: "Entries with notes show 'content missing' in the view when using model.notes.body in ERB"
component: ActionText::RichText / ActionText::Content
framework: Rails 8.1.2 / ActionText
related:
  - runtime-errors/action-text-sanitization-on-load-hook.md
---

# ActionText `.body` bypasses rendering pipeline — "content missing" for attachments

## Symptom

A show or detail view renders "content missing" where rich text notes should appear. The record was saved successfully and the rich text content exists in the database. The issue only manifests at render time.

```
content missing
```

This is ActionText's own output for an attachment it cannot resolve — not a custom error message and not from your templates.

## Root Cause

`has_rich_text :notes` defines `notes` as an `ActionText::RichText` association — a proxy object with its own rendering pipeline. Calling `.body` on that proxy returns an `ActionText::Content` object, which is an intermediate representation of the stored Trix document.

When an `ActionText::Content` object is passed directly to ERB's `<%= %>` interpolation, Rails calls `.to_s` on it. This **bypasses ActionText's rendering pipeline** entirely. Instead of invoking the ActionText partial (which resolves attachments, generates signed ActiveStorage URLs, and produces sanitized HTML), it tries to serialize the raw content. Any embedded attachment (image, file, mention) whose ActiveStorage blob or attachable record cannot be resolved is rendered as "content missing".

```erb
<%# WRONG — bypasses ActionText rendering pipeline %>
<%= @symptom_log.notes.body %>

<%# CORRECT — invokes ActionText rendering pipeline %>
<%= @symptom_log.notes %>
```

## Fix

Remove `.body` from the render call. Keep `.body` only on the `present?` guard — it is the correct way to test whether any content was saved.

```erb
<%# app/views/symptom_logs/show.html.erb — BEFORE %>
<% if @symptom_log.notes.body.present? %>
  <div class="timeline-notes">
    <%= @symptom_log.notes.body %>
  </div>
<% end %>

<%# AFTER %>
<% if @symptom_log.notes.body.present? %>
  <div class="timeline-notes">
    <%= @symptom_log.notes %>
  </div>
<% end %>
```

The `present?` guard stays on `.body` — checking `notes.present?` would always be truthy because `ActionText::RichText` is an association object, never nil.

## Why `<%= model.notes %>` Works

The `ActionText::RichText` object implements Rails' rendering protocol. Calling `<%= @record.notes %>` triggers `render` on the ActionText content partial (`actiontext/content`), which:

1. Sanitizes the stored HTML
2. Resolves each embedded `<action-text-attachment>` to its attachable record
3. Generates signed ActiveStorage blob URLs for any file/image attachments
4. Returns the final safe, rendered HTML markup

Calling `.body` hands you the raw `ActionText::Content` wrapper, which was never designed for direct template output.

## Correct Patterns

| Use case | Call |
|----------|------|
| Render rich text in a view | `<%= record.notes %>` |
| Check if any content was saved | `record.notes.body.present?` |
| Plain text preview (list rows, search) | `record.notes.to_plain_text` |
| Access raw Trix HTML (debugging only) | `record.notes.body.to_html` |

## Prevention

**Code review red flags:**

- `<%= model.rich_text_field.body %>` — the canonical form of this bug
- `<%= model.rich_text_field.body.to_s %>` — same problem, additionally strips HTML safety
- `<%= raw model.rich_text_field.body %>` — attempts to force raw output, bypasses ActionText
- Storing `.body` in a local variable (`body = model.notes.body`) then rendering it — less visible but identical

**Rule of thumb:** "`has_rich_text` gives you a proxy — call the proxy, not its guts."

`model.notes` is the complete, correct rendering call in a view. Anything after the dot is reaching past the abstraction layer into internals not designed for direct output.

## Known Occurrences Fixed

- `app/views/symptom_logs/show.html.erb` — fixed in commit `3a777ad`
- `app/views/health_events/show.html.erb` — same pattern, fix needed (see below)

## Additional Instance: `health_events/show.html.erb`

The Related Docs search found the same bug in health events:

```erb
<%# app/views/health_events/show.html.erb — line 73-76 %>
<% if @health_event.notes.body.present? %>
  <div class="event-row-notes" ...>
    <%= @health_event.notes.body %>   <%# BUG: should be @health_event.notes %>
```

This should be fixed with the same one-character change.
