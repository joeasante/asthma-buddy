---
title: "Fix three UAT gaps in symptom timeline: trend bar reactivity, filter chip active state, datetime validation"
date: "2026-03-07"
problem_type: "ui-bug"
component: "symptom timeline"
symptoms:
  - "Severity trend bar didn't update without a full page refresh after logging a new symptom"
  - "Filter preset chips (7d, 30d, 90d) didn't show visual active state after clicking"
  - "Datetime input rejected clean minute-boundary values with browser validation errors"
tags:
  - "hotwire"
  - "turbo-streams"
  - "turbo-frames"
  - "rails"
  - "datetime-local-field"
severity: "high"
status: "solved"
related:
  - "ui-bugs/hotwire-turbo-stream-form-validation-issues.md"
  - "ui-bugs/turbo-frame-top-blocks-stream-edit-in-place.md"
  - "ui-bugs/turbo-confirm-ignored-on-button-to.md"
---

# Turbo Hotwire: DOM Targeting, Frame Scope, and Datetime Validation

Three interconnected UAT-diagnosed bugs in a Rails 8.1.2 / Hotwire symptom timeline. All three share a common theme: **implicit assumptions about DOM stability, frame rendering scope, and browser input behaviour**.

---

## Symptoms

1. **Trend bar stale after create** — After submitting a new symptom log entry, the severity trend bar (showing mild/moderate/severe distribution) did not update. A full page reload was required.
2. **Filter chip active state broken** — Clicking a preset chip ("7 days", "30 days", etc.) filtered the timeline correctly, but the clicked chip never appeared visually active.
3. **Datetime browser validation errors** — The `datetime_local_field` caused browser validation failures, rejecting times that appeared valid to users.

---

## Root Cause & Solution

### Bug 1 — Trend bar not live-updating on create

**Root cause:** The `_trend_bar` partial had no stable DOM `id`, so `turbo_stream.replace` had no target to hook into. Additionally, the `create` action didn't compute `@severity_counts`, leaving the partial without data.

**Fix — three coordinated changes:**

**1. Wrap the trend bar in a stable container** (`index.html.erb`):
```erb
<div id="trend_bar">
  <%= render "trend_bar", severity_counts: @severity_counts %>
</div>
```

**2. Compute severity counts in the `create` action** (controller):
```ruby
if @symptom_log.save
  @severity_counts = { mild: 0, moderate: 0, severe: 0 }.merge(
    Current.user.symptom_logs.severity_counts
  )
  # ...respond_to block
end
```

Use full-history counts (no date filter) — the trend bar always reflects the user's complete history.

**3. Add the trend bar replacement as the FIRST operation** in `create.turbo_stream.erb`:
```erb
<%= turbo_stream.replace "trend_bar" do %>
  <div id="trend_bar">
    <%= render "trend_bar", severity_counts: @severity_counts %>
  </div>
<% end %>

<%# existing: prepend new row %>
<%= turbo_stream.prepend "timeline_list" do %>
  ...
<% end %>
```

The inner `id="trend_bar"` div must be included inside the `replace` block because `turbo_stream.replace` replaces the target element wholesale, including its wrapper.

---

### Bug 2 — Filter chip active state broken

**Root cause:** The `filter_bar` partial was rendered **outside** `turbo_frame_tag "timeline_content"`. When a chip was clicked, only the frame content refreshed — the bar (outside the frame) stayed stale with no active chip. The chip links used `data: { turbo_frame: "timeline_content" }`, but since the bar itself was outside the frame it was never re-rendered.

**Fix:** Move `filter_bar` render to be the **first item inside** `turbo_frame_tag "timeline_content"`.

**Before:**
```erb
<%= render "filter_bar",
      active_preset: @active_preset,
      start_date: @start_date,
      end_date: @end_date %>

<%= turbo_frame_tag "timeline_content" do %>
  <div id="trend_bar">...</div>
  <%# rest of timeline %>
<% end %>
```

**After:**
```erb
<%= turbo_frame_tag "timeline_content" do %>
  <%= render "filter_bar",
        active_preset: @active_preset,
        start_date: @start_date,
        end_date: @end_date %>

  <div id="trend_bar">
    <%= render "trend_bar", severity_counts: @severity_counts %>
  </div>
  <%# rest of timeline unchanged %>
<% end %>
```

The `_filter_bar.html.erb` partial itself doesn't change. With the bar inside the frame, every chip click re-renders the bar with the correct active class.

> **Note:** This supersedes an earlier architectural decision to keep the filter bar outside the frame. The root cause of the broken active state was that decision — this fix reverses it.

---

### Bug 3 — Datetime input browser validation errors

**Root cause:** `datetime_local_field` without a `step` attribute defaults to 1-second granularity. The pre-filled value used `Time.current`, which includes seconds. The browser's native validation rejected values that didn't align with the (implicit) step.

**Fix — three coordinated changes:**

**1. Add `step: 60` to the datetime input** (form partial):
```erb
<%= form.datetime_local_field :recorded_at, step: 60 %>
```

**2. Initialize without seconds in the `index` action** (controller):
```ruby
format.html do
  @symptom_log = Current.user.symptom_logs.new(
    recorded_at: Time.current.change(sec: 0)
  )
end
```

**3. Reset with the same format in `create.turbo_stream.erb`:**
```erb
recorded_at: Time.current.change(sec: 0)
```

`step: 60` sets the valid-value anchor to whole minutes. `Time.current.change(sec: 0)` ensures the pre-filled value always aligns with that anchor.

---

## Prevention Strategies

### Code Review Checklist

**Turbo Stream DOM targeting:**
- Every element targeted by a Turbo Stream (`replace`, `update`, `remove`, etc.) must have a hardcoded, stable `id` attribute
- Confirm the `id` is not dynamically generated from volatile data (timestamps, random tokens)
- For list items, use the record's primary key: `id="<%= dom_id(@log) %>"`
- For shared UI components (charts, counters, banners), use a semantic name: `id="trend_bar"`, `id="notification_count"`

**Turbo Frame scope:**
- Every partial that shows state relative to the current frame navigation (active tabs, selected chips, current page number) must be rendered **inside** the frame
- If a partial lives outside the frame, it can only show static content — it will not respond to frame navigations
- When reviewing `turbo_frame_tag` blocks, check that all state-dependent partials are inside the closing `<% end %>`

**Datetime inputs:**
- Every `datetime_local_field`, `time_field`, or `date_field` must include an explicit `step:` attribute
- Default: `step: 60` (minute precision) unless seconds are genuinely needed
- Default values must use `Time.current.change(sec: 0)` to match the step anchor

### Test Cases to Add

**Turbo Stream DOM targeting:**
```ruby
test "create turbo stream response includes trend_bar replace" do
  post symptom_logs_url,
    params: { symptom_log: { symptom_type: "coughing", severity: "severe",
                              recorded_at: Time.current } },
    headers: { "Accept" => "text/vnd.turbo-stream.html" }
  assert_response :success
  assert_match "trend_bar", response.body
end
```

**Filter chip active state (system test):**
```ruby
within(".filter-bar") { click_on "7 days" }
# Active chip state must update (filter_bar inside the frame)
assert_selector ".filter-chip--active", text: "7 days"
```

**Datetime step validation:**
- Include a test that submits the form with a clean-minute datetime and confirms no validation error
- Test that the pre-filled `recorded_at` value has `seconds == 0`

### Rails/Hotwire Conventions

- **Use `dom_id` helper** for record-specific targets: `<div id="<%= dom_id(@post) %>">` — consistent, unique, and collision-free
- **Frame partials as self-contained units** — a partial that must respond to frame navigation belongs inside the frame, full stop
- **`step:` is mandatory for datetime inputs** — treat it like `type:` on an input; never omit it

---

## Related Documentation

- [`ui-bugs/hotwire-turbo-stream-form-validation-issues.md`](hotwire-turbo-stream-form-validation-issues.md) — HTML `required` blocking Turbo Stream validation responses; missing instance variables in create failure paths
- [`ui-bugs/turbo-frame-top-blocks-stream-edit-in-place.md`](turbo-frame-top-blocks-stream-edit-in-place.md) — `data-turbo-frame="_top"` breaking stream responses and causing full page navigation on edit-in-place
- [`ui-bugs/turbo-confirm-ignored-on-button-to.md`](turbo-confirm-ignored-on-button-to.md) — `data-turbo-confirm` on `button_to` failing silently; confirmation must be on the `<form>` not the `<button>`
