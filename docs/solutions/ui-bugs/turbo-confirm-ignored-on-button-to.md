---
title: data-turbo-confirm ignored on button_to (confirmation dialog never appears)
category: ui-bugs
tags: [turbo, hotwire, button_to, data-turbo-confirm, rails, delete, confirmation]
symptoms:
  - Clicking a delete button executes the action immediately with no confirmation dialog
  - data-turbo-confirm attribute appears to have no effect
components:
  - button_to helper
  - generated <form> element wrapping button_to
  - Turbo confirm handler
related:
  - docs/solutions/ui-bugs/hotwire-turbo-stream-form-validation-issues.md
  - docs/solutions/ui-bugs/turbo-frame-top-blocks-stream-edit-in-place.md
---

## Problem

`data-turbo-confirm` placed on a `button_to` call does not show a confirmation dialog — the action fires immediately.

## Root Cause

Turbo reads `data-turbo-confirm` from the **`<form>`** element, not from child elements like `<button>`. Rails' `button_to` helper wraps the button in a `<form>`. When `turbo_confirm` is passed in the button's `data:` hash, Rails renders the attribute on the `<button>` tag, which Turbo ignores entirely.

## Wrong Code

```erb
<%# turbo_confirm on the button — Turbo never sees this %>
<%= button_to "Delete", resource_path(resource), method: :delete,
      class: "btn-delete",
      data: { turbo_confirm: "Delete this entry?" } %>
```

This generates:
```html
<form method="post" action="/resources/1">
  <input type="hidden" name="_method" value="delete">
  <button class="btn-delete" data-turbo-confirm="Delete this entry?" type="submit">Delete</button>
</form>
```

Turbo looks at the `<form>`, finds no `data-turbo-confirm`, and submits without prompting.

## Fix

Use the `form:` option to pass attributes to the wrapping `<form>` element:

```erb
<%= button_to "Delete", resource_path(resource), method: :delete,
      class: "btn-delete",
      form: { data: { turbo_confirm: "Delete this entry?" } } %>
```

This generates:
```html
<form data-turbo-confirm="Delete this entry?" method="post" action="/resources/1">
  <input type="hidden" name="_method" value="delete">
  <button class="btn-delete" type="submit">Delete</button>
</form>
```

Turbo intercepts the form submission, reads `data-turbo-confirm` from the form, and shows the native browser `window.confirm()` dialog before proceeding.

## Detection

If a confirmation dialog silently fails to appear, inspect the rendered HTML and check whether `data-turbo-confirm` is on the `<form>` tag or the `<button>` tag. If it is on the button, that is the bug.

## Prevention Rule

> For `button_to`, always put Turbo data attributes in the `form:` option hash, never directly on the button.

## Tests

```ruby
test "delete requires confirmation before removing entry" do
  visit symptom_logs_path

  dismiss_confirm { click_button "Delete" }
  assert SymptomLog.exists?(@symptom_log.id), "entry should not be deleted on dismiss"

  accept_confirm { click_button "Delete" }
  assert_not SymptomLog.exists?(@symptom_log.id), "entry should be deleted on accept"
end
```

## Common Mistake

Passing `data: { turbo_confirm: "..." }` as a top-level option to `button_to`. Rails places top-level `data:` options on the `<button>` element, not the wrapping `<form>`. Only `form: { data: { ... } }` targets the form.
