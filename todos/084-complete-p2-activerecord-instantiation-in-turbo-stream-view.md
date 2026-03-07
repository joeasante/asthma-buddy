---
status: pending
priority: p2
issue_id: "084"
tags: [code-review, rails, architecture, hotwire]
dependencies: ["077"]
---

# ActiveRecord Object Instantiated in Turbo Stream View

## Problem Statement

`create.turbo_stream.erb` calls `Current.user.peak_flow_readings.new(recorded_at: Time.current.change(sec: 0))` directly in the view. Constructing model objects (even unsaved in-memory ones) belongs in the controller, not the view. While `.new` doesn't fire a DB query here, it violates the layering rule and sets a precedent that makes future view queries more likely. The controller should prepare `@new_peak_flow_reading` and pass it to the template.

Note: todo 066 was previously marked complete for a related DB query concern — this is a distinct finding about model instantiation in views (not a DB query, but still a layering violation).

## Findings

**Flagged by:** kieran-rails-reviewer (P1), architecture-strategist (P2b)

**Location** (`app/views/peak_flow_readings/create.turbo_stream.erb:4–8`):
```erb
<%= turbo_stream.replace "peak_flow_reading_form" do %>
  <%= turbo_frame_tag "peak_flow_reading_form" do %>
    <%= render "form",
          peak_flow_reading: Current.user.peak_flow_readings.new(  ← model in view
            recorded_at: Time.current.change(sec: 0)
          ),
          has_personal_best: @has_personal_best %>
  <% end %>
<% end %>
```

## Proposed Solutions

### Option A: Assign in controller, use ivar in view (Recommended)
**Effort:** Small | **Risk:** Low

```ruby
# app/controllers/peak_flow_readings_controller.rb
# In create success branch:
if @peak_flow_reading.save
  @flash_message = zone_flash_message(@peak_flow_reading)
  @has_personal_best = @peak_flow_reading.personal_best_at_reading_time.present?
  @new_peak_flow_reading = Current.user.peak_flow_readings.new(
    recorded_at: Time.current.change(sec: 0)
  )
  respond_to { ... }
end
```

```erb
<%# create.turbo_stream.erb %>
<%= turbo_stream.replace "peak_flow_reading_form" do %>
  <%= turbo_frame_tag "peak_flow_reading_form" do %>
    <%= render "form",
          peak_flow_reading: @new_peak_flow_reading,
          has_personal_best: @has_personal_best %>
  <% end %>
<% end %>
```

## Recommended Action

Option A — assign in controller, reference ivar in view. One-line change in controller, one-line change in view. Makes the view a pure rendering layer with no logic.

## Technical Details

**Affected files:**
- `app/controllers/peak_flow_readings_controller.rb`
- `app/views/peak_flow_readings/create.turbo_stream.erb`

## Acceptance Criteria

- [ ] `create.turbo_stream.erb` contains no ActiveRecord or model calls
- [ ] `@new_peak_flow_reading` set in controller success branch
- [ ] `bin/rails test` passes with 0 failures

## Work Log

- 2026-03-07: Identified by kieran-rails-reviewer and architecture-strategist in Phase 6 code review
