---
title: "Page header eyebrow stats go stale after Turbo Stream mutations"
problem_type: ui-bugs
component: page-header / turbo-stream
symptoms:
  - Page header eyebrow displays outdated statistics after Turbo Stream responses
  - Stats like unread count, entries this month, low stock count don't refresh inline
  - Data on the page updates but the header stats remain unchanged
tags:
  - turbo-streams
  - hotwire
  - view-rendering
  - partial-updates
  - page-header
related:
  - docs/solutions/ui-bugs/turbo-stream-dom-coupling-ui-redesign.md
  - docs/solutions/ui-bugs/turbo-stream-flash-messages-and-frame-preservation.md
  - docs/solutions/ui-bugs/turbo-hotwire-dom-targeting-and-frame-rendering.md
solved: true
---

## Problem

Pages in Asthma Buddy follow a consistent `.page-header` pattern with a `.page-header-eyebrow` section showing live stats — e.g. "4 unread · Last alert: 10 min ago", "3 entries this month", "2 low stock". When Turbo Stream responses mutated data inline (mark read, create, destroy, refill), the eyebrow stats didn't update. Users saw stale numbers until they did a full page reload.

## Root Cause

The page header was rendered **inline** inside each `index.html.erb`. Turbo Stream responses could only replace DOM elements they could target by id. Because the inline page header had no stable id, there was nothing to target — the stats stayed frozen at their initial server-rendered values.

## Solution

### 1. Extract the page header to a partial with a stable DOM id

Create `app/views/{controller}/_page_header.html.erb`. Put the id on the outer div and use **locals** (not `@ivars`) so the partial can be rendered from both the index action and Turbo Stream templates.

```erb
<%# app/views/symptom_logs/_page_header.html.erb %>
<div id="symptom-logs-page-header" class="page-header">
  <div class="page-header-eyebrow">
    <% if last_log %>
      <span class="eyebrow-stat">Last logged:
        <strong><%= last_log.recorded_at.to_date == Date.current ? "today" : last_log.recorded_at.strftime("%-d %b") %></strong>
      </span>
      <span class="eyebrow-dot" aria-hidden="true"></span>
    <% end %>
    <span class="eyebrow-stat">
      <strong><%= month_count %></strong> <%= "entry".pluralize(month_count) %> this month
    </span>
    <div class="eyebrow-rule" aria-hidden="true"></div>
  </div>
  <%# ... rest of page-header-main ... %>
</div>
```

### 2. Replace the inline block in the index view

```erb
<%# BEFORE %>
<div class="page-header">
  ...all the inline markup...
</div>

<%# AFTER %>
<%= render "page_header", last_log: @header_last_log, month_count: @header_month_count %>
```

### 3. Compute header vars in mutation actions

Add a private helper and call it in every action that renders `turbo_stream`:

```ruby
# app/controllers/symptom_logs_controller.rb

def destroy
  @symptom_log.destroy
  @severity_counts = { mild: 0, moderate: 0, severe: 0 }.merge(
    Current.user.symptom_logs.severity_counts
  )
  set_header_eyebrow_vars   # <-- compute fresh header data
  respond_to { |f| f.turbo_stream }
end

private

def set_header_eyebrow_vars
  all_logs = Current.user.symptom_logs.chronological
  @header_last_log    = all_logs.first
  @header_month_count = all_logs.where(recorded_at: Date.current.beginning_of_month..).count
end
```

### 4. Add `turbo_stream.replace` in every relevant Turbo Stream template

```erb
<%# app/views/symptom_logs/destroy.turbo_stream.erb %>

<%= turbo_stream.replace "symptom-logs-page-header" do %>
  <%= render "page_header", last_log: @header_last_log, month_count: @header_month_count %>
<% end %>

<%= turbo_stream.replace "trend_bar" do %>...<%  end %>
<%= turbo_stream.remove dom_id(@symptom_log) %>
<%= turbo_stream.replace "flash-messages" do %>...<%  end %>
```

The header replace should come **first** so the stats are visibly consistent with the updated list.

## Pages Fixed in This Session

| Partial | DOM id | Turbo Streams that replace it |
|---------|--------|-------------------------------|
| `notifications/_page_header.html.erb` | `notifications-page-header` | `mark_read`, `mark_all_read` |
| `symptom_logs/_page_header.html.erb` | `symptom-logs-page-header` | `create`, `update`, `destroy` |
| `peak_flow_readings/_page_header.html.erb` | `peak-flow-page-header` | `destroy` |
| `settings/medications/_page_header.html.erb` | `medications-page-header` | `create`, `update`, `destroy`, `refill`, `dose_logs/create`, `dose_logs/destroy` |

Note: the `settings/dose_logs` controller also calls `set_header_eyebrow_vars` and its Turbo Stream templates replace `medications-page-header` — because logging or removing a dose can flip the "All stocked" / "X low stock" pill.

## Key Insight

Partials must use **locals, not `@ivars`**. This is the critical unlock — it allows the same partial to be rendered from both:
- The `index` action (passing `@header_last_log` as a local), and
- Any Turbo Stream template (passing freshly computed data as a local)

If the partial reads `@header_last_log` directly, Turbo Stream templates can't provide a different value and the update is impossible.

## Prevention

### Rule

> Every page header with eyebrow stats must be an extracted partial with a stable DOM id, using locals — and every mutation action that affects those stats must (a) compute fresh header data and (b) include a `turbo_stream.replace` targeting that id.

### Checklist when adding a new page

- [ ] Page header extracted to `_page_header.html.erb` with `id="{resource}-page-header"` on the outer div
- [ ] Partial uses locals, not `@ivars`
- [ ] `index` action sets `@header_*` ivars and passes them as locals
- [ ] Private `set_header_eyebrow_vars` method exists for reuse across mutation actions

### Checklist when adding a new Turbo Stream action

- [ ] Action calls `set_header_eyebrow_vars` (or inline equivalent) before `respond_to`
- [ ] Turbo Stream template includes `turbo_stream.replace "{resource}-page-header"`
- [ ] DOM id in template matches the id in the partial
- [ ] If another controller's mutations also affect this page's stats, update that controller too

### Code review flags

- Page header rendered inline with no id → extract it
- Partial rendered with `render "page_header"` and no locals → pass locals
- Mutation action with `format.turbo_stream` but no `set_header_eyebrow_vars` call → add it
- Turbo Stream template that mutates a list but has no header replace → add it

### Controller test to verify header is replaced

```ruby
test "destroy replaces page header in Turbo Stream response" do
  post mark_all_read_notifications_path,
       headers: { "Accept" => "text/vnd.turbo-stream.html" }
  assert_response :success
  assert_match(/notifications-page-header/, response.body)
end
```
