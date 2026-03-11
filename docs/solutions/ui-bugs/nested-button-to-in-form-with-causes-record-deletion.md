---
title: "Rails button_to inside form_with causes destroy instead of update"
date: 2026-03-10
category: ui-bugs
tags: [rails, hotwire, turbo, forms, nested-forms, html, button_to, form_with]
symptoms:
  - "Clicking 'Update' on an edit form triggers destroy action instead"
  - "Flash message says 'X removed' after submitting an edit form"
  - "Record disappears from list after clicking save/update"
  - "Form submission routes to wrong controller action"
components:
  - "app/views/settings/medications/_form.html.erb"
root_cause: "button_to with method: :delete nested inside form_with block causes HTML parser to hoist the inner form's _method=delete hidden input into outer form scope, overriding the form's PATCH method with DELETE"
fix_approach: "Move button_to delete block outside and after the form_with end tag"
related: []
---

# Rails `button_to` inside `form_with` causes destroy instead of update

## Problem

Clicking "Update medication" on an edit form deleted the record instead of saving changes. The flash message read "Medication removed." and the record disappeared from the list.

## Root Cause

In `app/views/settings/medications/_form.html.erb`, the delete button was placed inside the `form_with` block:

```erb
<%= form_with model: [...], ... do |form| %>
  ... form fields ...

  <div class="form-actions">
    <%= form.submit "Update medication", class: "btn-primary" %>
  </div>

  <% if medication.persisted? %>
    <div class="form-delete-zone">
      <%= button_to "Delete medication", settings_medication_path(medication), method: :delete,
            class: "btn-delete btn-delete--full",
            form: { data: { turbo: true, turbo_confirm: "Delete...?" } } %>
    </div>
  <% end %>
<% end %>
```

The `button_to` helper generates its own `<form>` tag with `method="post"` and a hidden `_method=delete` input:

```html
<form method="post" action="/settings/medications/123">
  <input type="hidden" name="_method" value="delete">
  <button type="submit">Delete medication</button>
</form>
```

**HTML forbids nested `<form>` elements.** When the browser's parser encounters a `<form>` inside another `<form>`, it strips the inner form tag but keeps its contents — including the `_method=delete` hidden input. That input is now part of the outer edit form. When the user clicks "Update medication", the outer form submits POST with `_method=delete` → Rails routes to `destroy` → record is deleted silently.

## Solution

Move the delete zone completely outside the `form_with` block:

```erb
<%= form_with model: [...], ... do |form| %>
  ... form fields ...

  <div class="form-actions">
    <%= form.submit "Update medication", class: "btn-primary" %>
  </div>
<% end %>

<% if medication.persisted? %>
  <div class="form-delete-zone">
    <%= button_to "Delete medication", settings_medication_path(medication), method: :delete,
          class: "btn-delete btn-delete--full",
          form: { data: { turbo: true, turbo_confirm: "Delete...?" } } %>
  </div>
<% end %>
```

Two separate, valid HTML forms with independent submission paths. The edit form submits PATCH; the delete button generates its own form that submits DELETE. No cross-contamination.

## Prevention

**Never nest `button_to` inside a `form_with` block.**

The HTML specification explicitly forbids nested `<form>` elements. The visual temptation is strong — the delete button logically belongs "with" the edit form — but HTML structure must match intent.

**Code review checklist:**
- Scan ERB templates for `button_to` calls between a `form_with` and its closing `end`
- Flag every instance, especially those with `method: :delete`

**Alternative:** Use `link_to` with `data: { turbo_method: :delete }` — generates a plain `<a>` tag, no form nesting risk:

```erb
<%= link_to "Delete", resource_path(resource),
    data: { turbo_method: :delete, turbo_confirm: "Are you sure?" },
    class: "btn-delete" %>
```

## Detection

**Symptom is subtle:** edit form appears normal, but clicking submit deletes the record with no warning.

**Diagnose:**

1. Check Rails logs — you expect `PATCH /resources/1` but see `DELETE /resources/1`
2. Inspect the rendered HTML in DevTools — search for `<input name="_method" value="delete">` inside the edit form

**Test to catch this class of bug:**

```ruby
test "edit form submits PATCH not DELETE" do
  sign_in_as users(:alice)
  patch settings_medication_path(@medication), params: { medication: { name: "Updated" } }
  assert_response :redirect
  assert_equal "Updated", @medication.reload.name
end
```
