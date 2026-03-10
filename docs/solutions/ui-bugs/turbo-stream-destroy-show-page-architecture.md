---
title: "Turbo Stream Destroy: Show-Page Architecture Removes Need for turbo_stream.remove"
problem_type: "ui-bugs"
severity: "medium"
tags: ["Turbo Streams", "turbo_stream.remove", "show page", "destroy", "toast", "REST", "Hotwire"]
components: ["turbo_stream", "destroy.turbo_stream.erb", "controllers", "show pages"]
solved: "2026-03-10"
---

# Turbo Stream Destroy: Show-Page Architecture Removes Need for `turbo_stream.remove`

## Problem Symptom

After refactoring index rows from inline `<article>` elements with edit/delete buttons to
`link_to show_path` links, delete still works but the `destroy.turbo_stream.erb` contains a
stale `turbo_stream.remove dom_id(@record)` that silently targets a DOM element that doesn't
exist on the show page.

No visible error — Turbo silently no-ops on missing targets — but the code is misleading,
and the toast/feedback may not fire correctly if the remove operation is entangled with it.

## Root Cause

The destroy turbo stream was written for an index-row delete pattern (user clicks delete
on a row in the list). After converting rows to show-page links, delete is triggered from
the show page. The user is on `/readings/123`, not `/readings` — so the index row element
`<div id="peak_flow_reading_123">` does not exist in the current DOM.

## Original (Stale After Refactor)

```erb
<%# app/views/peak_flow_readings/destroy.turbo_stream.erb %>
<%# Remove the table row %>
<%= turbo_stream.remove dom_id(@peak_flow_reading) %>
<%= turbo_stream.replace "flash-messages" do %>
  <%= render "layouts/flash", notice: "Reading deleted." %>
<% end %>
```

## Working Solution

```erb
<%# app/views/peak_flow_readings/destroy.turbo_stream.erb %>
<%= turbo_stream.replace "flash-messages" do %>
  <div id="flash-messages"
       data-controller="toast"
       data-toast-message="Reading deleted."
       data-toast-variant="success">
  </div>
<% end %>
```

### Why It Works

When delete is triggered from the show page, Rails follows the `format.html` path (redirect
to index) — not the Turbo Stream path — because show pages don't send `text/vnd.turbo-stream.html`
Accept headers by default. The user is naturally navigated back to the index with a flash notice.

The Turbo Stream response is only reached if a client explicitly requests it (e.g., via
`data: { turbo_stream: true }` or custom headers). In that case, only the toast is needed
— the row removal is irrelevant because the caller is on the show page, not the index.

## Architecture Decision Tree

```
Does delete happen from the show page?
│
├─ YES → Return toast only. User navigates back to index naturally (HTML redirect).
│        turbo_stream.replace "flash-messages" only.
│
├─ NO (index page only) → Include turbo_stream.remove + toast.
│        Row disappears inline.
│
└─ BOTH → Either:
   (a) Include remove + toast. Remove is a no-op on show page (safe silent fail).
   (b) Use request.referer to conditionally include remove.
       Approach (a) is simpler — prefer it.
```

## Show-Page Architecture Pattern (Applied in Phase 15+)

When converting a resource to have a proper show page:

1. **Index rows** become `link_to resource_path(record)` — remove edit/delete buttons from rows
2. **Show page** hosts the edit button and delete button
3. **destroy.turbo_stream.erb** — remove `turbo_stream.remove`, keep only toast
4. **Controller destroy action** — add `format.html { redirect_to resources_path }` to redirect
   after delete from show page
5. **Dashboard/parent links** — update from `edit_*_path` → `*_path` (show path)

```ruby
# Controller: ensure HTML redirect for show-page deletes
def destroy
  @reading = Current.user.peak_flow_readings.find(params[:id])
  @reading.destroy
  respond_to do |format|
    format.turbo_stream  # toast only — see destroy.turbo_stream.erb
    format.html { redirect_to peak_flow_readings_path, notice: "Reading deleted." }
  end
end
```

## Prevention Checklist

- [ ] When adding a show page to an existing resource, audit `destroy.turbo_stream.erb`
- [ ] Ask: "Where does the user see the Delete button?" Show page → remove `turbo_stream.remove`
- [ ] Confirm `format.html { redirect_to index_path }` is present in the destroy action
- [ ] Test delete from the show page: confirm redirect to index with toast, no JS errors

## Detection Test

```ruby
# test/controllers/peak_flow_readings_controller_test.rb
test "destroy from show page redirects to index (not turbo stream)" do
  reading = peak_flow_readings(:alice_green_reading)
  delete peak_flow_reading_path(reading)  # no turbo stream Accept header
  assert_redirected_to peak_flow_readings_path
end

test "destroy turbo stream response includes toast" do
  reading = peak_flow_readings(:alice_green_reading)
  delete peak_flow_reading_path(reading),
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
  assert_response :success
  assert_match "Reading deleted", response.body
end
```

## Context

Applied across three resources in Phase 15 (Health Events / show pages):
- `app/views/peak_flow_readings/destroy.turbo_stream.erb`
- `app/views/symptom_logs/destroy.turbo_stream.erb`
- `app/views/health_events/destroy.turbo_stream.erb`

The pattern was triggered by the Phase 15 plan to add show pages so dashboard chips link to
read-only detail views instead of jumping straight into edit forms.
