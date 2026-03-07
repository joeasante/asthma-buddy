---
status: pending
priority: p1
issue_id: "075"
tags: [code-review, hotwire, turbo, rails]
dependencies: []
---

# Turbo Frame Silently Destroyed on Validation Error

## Problem Statement

The success path of `PeakFlowReadingsController#create` wraps the re-rendered form in a `turbo_frame_tag` to preserve the `<turbo-frame>` element in the DOM after the `turbo_stream.replace`. The validation error path does NOT apply this wrapper — it renders the partial directly. This asymmetry means a validation failure replaces the `<turbo-frame>` element with a bare `<div>` (the partial's root element), destroying the frame. Any subsequent valid submission would then find no frame to replace and silently fail — the user would see no response.

## Findings

**Flagged by:** pattern-recognition-specialist (P2-3)

**Success path** (wrapped correctly) — `app/views/peak_flow_readings/create.turbo_stream.erb:1–10`:

```erb
<%= turbo_stream.replace "peak_flow_reading_form" do %>
  <%= turbo_frame_tag "peak_flow_reading_form" do %>  ← frame preserved
    <%= render "form", ... %>
  <% end %>
<% end %>
```

**Error path** (frame NOT preserved) — `app/controllers/peak_flow_readings_controller.rb:27–33`:

```ruby
format.turbo_stream do
  render turbo_stream: turbo_stream.replace(
    "peak_flow_reading_form",
    partial: "form",
    locals: { peak_flow_reading: @peak_flow_reading, has_personal_best: @has_personal_best }
  ), status: :unprocessable_entity
end
```

This renders the `_form.html.erb` partial as the replacement content — without a `<turbo-frame>` wrapper. After the replace, the `<turbo-frame id="peak_flow_reading_form">` element is gone from the DOM.

**Reproduction:** Submit a reading with an out-of-range value (e.g. 1500). Then try to submit a valid value — the form will not respond.

## Proposed Solutions

### Option A: Wrap error path in turbo_frame_tag (Recommended)
**Effort:** Small | **Risk:** Low

Use a block form for the error render that includes the `turbo_frame_tag` wrapper:

```ruby
format.turbo_stream do
  render turbo_stream: turbo_stream.replace("peak_flow_reading_form") {
    view_context.turbo_frame_tag("peak_flow_reading_form") {
      view_context.render(partial: "form",
                          locals: { peak_flow_reading: @peak_flow_reading,
                                    has_personal_best: @has_personal_best })
    }
  }, status: :unprocessable_entity
end
```

Or extract an error Turbo Stream response to a partial (see Option B).

### Option B: Extract error response to turbo_stream ERB partial
**Effort:** Small | **Risk:** Low

Create `app/views/peak_flow_readings/error.turbo_stream.erb`:

```erb
<%= turbo_stream.replace "peak_flow_reading_form" do %>
  <%= turbo_frame_tag "peak_flow_reading_form" do %>
    <%= render "form", peak_flow_reading: @peak_flow_reading, has_personal_best: @has_personal_best %>
  <% end %>
<% end %>
```

Controller becomes:

```ruby
format.turbo_stream do
  render :error, status: :unprocessable_entity
end
```

### Option C: Embed the form in a turbo_frame in the partial itself
**Effort:** Medium | **Risk:** Medium

Wrap the form content in `_form.html.erb` within a `turbo_frame_tag`, then use `turbo_stream.update` instead of `replace`. This eliminates the need for the controller/stream to supply the frame wrapper.

## Recommended Action

Option B — extract error response to `error.turbo_stream.erb`. Keeps the controller clean, mirrors the success path structure exactly, and is easy to test.

## Technical Details

**Affected files:**
- `app/controllers/peak_flow_readings_controller.rb` (lines 27–33)
- `app/views/peak_flow_readings/error.turbo_stream.erb` (new)

## Acceptance Criteria

- [ ] Submit an invalid reading (value > 900 or empty) — validation errors appear inline
- [ ] After seeing errors, submit a valid reading — form resets and flash appears normally
- [ ] `bin/rails test` passes with 0 failures
- [ ] System test for validation error → valid submission flow passes

## Work Log

- 2026-03-07: Identified by pattern-recognition-specialist in Phase 6 code review
