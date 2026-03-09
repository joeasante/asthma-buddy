---
title: turbo_frame "_top" on form_with blocks Turbo Stream edit-in-place
category: ui-bugs
tags: [turbo, hotwire, turbo-frame, turbo-stream, form_with, edit-in-place, rails]
symptoms:
  - Submitting an inline edit form causes a full page navigation instead of updating in place
  - The updated entry appears at the wrong position (e.g., bottom of a list) after save
  - The Turbo Stream replace/update response appears to be ignored
components:
  - form_with helper
  - turbo-frame element wrapping the entry
  - update.turbo_stream.erb template
related:
  - docs/solutions/ui-bugs/hotwire-turbo-stream-form-validation-issues.md
  - docs/solutions/ui-bugs/turbo-confirm-ignored-on-button-to.md
---

## Problem

Adding `data: { turbo_frame: "_top" }` to a `form_with` inside a `<turbo-frame>` breaks the edit-in-place pattern. Instead of replacing the entry in place, the form submission causes a full page navigation, and the updated entry appears elsewhere on the page (e.g., at the bottom of the list).

## Root Cause

When a form has `data-turbo-frame="_top"`, Turbo targets the top-level page frame rather than the enclosing `<turbo-frame>`. Crucially, Turbo does **not** include `text/vnd.turbo-stream.html` in the Accept header when the target is `_top`. The server receives a regular HTML request, responds with a redirect to the index page, and Turbo performs a full page navigation. The entry then appears wherever it would on the index page (e.g., in the "Recent Entries" list section below the form area) — which the user perceives as the entry appearing "below the form."

The form's enclosing `<turbo-frame>` already handles scoping correctly. When the form is inside `<turbo-frame id="resource_1">`, Turbo automatically includes `text/vnd.turbo-stream.html` in the Accept header, the server responds with a stream, and `turbo_stream.replace` swaps the frame's content in place. No additional `data-turbo-frame` is needed.

## Wrong "Fix"

```erb
<%# DO NOT add turbo_frame: "_top" — it breaks stream responses %>
<%= form_with model: resource, data: { turbo: true, turbo_frame: "_top" } do |form| %>
  ...
<% end %>
```

## Correct Code

```erb
<%# The enclosing turbo-frame handles scoping — no turbo_frame needed on the form %>
<%= form_with model: resource, data: { turbo: true } do |form| %>
  ...
<% end %>
```

## Full Pattern

**`edit.html.erb`** — wraps form in the entry's own turbo-frame:
```erb
<%= turbo_frame_tag dom_id(@resource) do %>
  <%= render "form", resource: @resource %>
<% end %>
```

**`_resource.html.erb`** (list partial) — entry also wraps in the same frame id:
```erb
<%= turbo_frame_tag dom_id(resource) do %>
  <article>
    <%# ... entry content ... %>
    <%= link_to "Edit", edit_resource_path(resource) %>
  </article>
<% end %>
```

**`update.turbo_stream.erb`** — replaces the frame in place:
```erb
<%= turbo_stream.replace dom_id(@resource),
      partial: "resource",
      locals: { resource: @resource } %>
```

When Edit is clicked, Turbo loads `edit.html.erb` into the matching frame. When the form is submitted, Turbo sends `text/vnd.turbo-stream.html` in Accept, the controller renders `update.turbo_stream.erb`, and `turbo_stream.replace` swaps the content exactly where it sits in the DOM.

## Detection

If a Turbo Stream response appears to be ignored and the page navigates instead:

1. Open the Network tab in DevTools
2. Find the form submission request
3. Check the `Accept` header — if it does **not** include `text/vnd.turbo-stream.html`, a `data-turbo-frame="_top"` (or equivalent) is overriding the frame target
4. Check the response — if it is a `302` redirect to the index path, the server is falling back to HTML

## Prevention Rule

> Never add `data: { turbo_frame: "_top" }` to a `form_with` inside a `<turbo-frame>` that is meant to receive a Turbo Stream response. The wrapping frame handles all scoping automatically.

`data-turbo-frame="_top"` is appropriate for **navigation links** that need to break out of a frame — it is not appropriate for forms that should stay within the frame and receive stream updates.

## Tests

```ruby
test "inline edit updates entry in place without full page reload" do
  visit resources_path

  within "##{dom_id(@resource)}" do
    click_link "Edit"
    select "severe", from: "Severity"
    click_button "Update"
    assert_text "severe"
  end

  # Verify no full navigation occurred — surrounding content unchanged
  assert_selector "h1", text: "My Resources"
end
```
