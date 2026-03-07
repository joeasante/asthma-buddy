---
status: pending
priority: p1
issue_id: "074"
tags: [code-review, security, xss, rails, hotwire]
dependencies: []
---

# `html_safe` + `raw` in Flash Pipeline — Structural XSS Risk

## Problem Statement

`zone_flash_message` in `PeakFlowReadingsController` builds an HTML string via string interpolation and calls `.html_safe` on the result. The Turbo Stream view then renders it with `raw @flash_message`. This is the archetypal unsafe HTML generation pattern in Rails. While safe today (values come from an enum and an integer), the pattern creates an invisible structural XSS risk: any future developer adding user-controlled content to the flash message will inherit the `.html_safe` call and silently produce reflected XSS.

The HTML redirect path also passes this raw HTML string as `notice:` in a redirect, but the layout renders `notice` with `<%= notice %>` (auto-escaped), so the HTML fallback path renders escaped entities (e.g. `&lt;span...&gt;`) as visible text rather than rendered HTML — an inconsistency between the Turbo Stream path and the HTML fallback path.

## Findings

**Flagged by:** security-sentinel (F-01, F-02, F-03), kieran-rails-reviewer (P2), pattern-recognition-specialist (P1-2), architecture-strategist (P2), code-simplicity-reviewer

**Location 1:** `app/controllers/peak_flow_readings_controller.rb:46–54`

```ruby
def zone_flash_message(reading)
  if reading.zone.nil?
    "Reading saved \u2014 set your personal best to see your zone."
  else
    zone_name = reading.zone.capitalize
    pct       = reading.zone_percentage
    coloured  = "<span class=\"zone-label zone-label--#{reading.zone}\">#{zone_name} Zone (#{pct}% of personal best)</span>"
    "Reading saved \u2014 #{coloured}.".html_safe   # ← structural XSS risk
  end
end
```

**Location 2:** `app/views/peak_flow_readings/create.turbo_stream.erb:15`

```erb
<p role="status" class="flash flash--notice"><%= raw @flash_message %></p>
```

The `raw` call is an unconditional XSS sink — any future path that sets `@flash_message` renders unescaped.

**Location 3 (inconsistency):** `app/controllers/peak_flow_readings_controller.rb:21`

```ruby
format.html { redirect_to new_peak_flow_reading_path, notice: @flash_message }
```

The layout renders `notice` with `<%= notice %>` (auto-escaped), producing visible HTML entities for users on the non-Turbo HTML fallback path.

## Proposed Solutions

### Option A: Move to helper with `content_tag` (Recommended)
**Effort:** Small | **Risk:** Low

Move `zone_flash_message` to `PeakFlowReadingsHelper`. Use `content_tag` which HTML-escapes its arguments and produces a `SafeBuffer`. Replace `raw` with `<%= @flash_message %>` in the view (Rails passes `SafeBuffer` through unchanged; escapes ordinary `String`).

```ruby
# app/helpers/peak_flow_readings_helper.rb
module PeakFlowReadingsHelper
  def zone_flash_message(reading)
    return "Reading saved \u2014 set your personal best to see your zone." if reading.zone.nil?

    label = content_tag(:span,
                        "#{reading.zone.capitalize} Zone (#{reading.zone_percentage}% of personal best)",
                        class: "zone-label zone-label--#{reading.zone}")
    safe_join(["Reading saved \u2014 ", label, "."])
  end
end
```

Controller calls `helpers.zone_flash_message(@peak_flow_reading)` (or move the call to the Turbo Stream template itself).

View: `<%= @flash_message %>` — no `raw` needed.

For the HTML redirect path, the `SafeBuffer` will be stored in flash and Rails will render it correctly.

### Option B: Keep in controller, use `content_tag`
**Effort:** Small | **Risk:** Low

Same fix but keep the method in the controller. Rails controllers include `ActionView::Helpers::TagHelper` when using `helpers`, or use `ActionController::Base` helper proxy:

```ruby
def zone_flash_message(reading)
  return "Reading saved \u2014 set your personal best to see your zone." if reading.zone.nil?

  label = helpers.content_tag(:span,
                               "#{reading.zone.capitalize} Zone (#{reading.zone_percentage}% of personal best)",
                               class: "zone-label zone-label--#{reading.zone}")
  helpers.safe_join(["Reading saved \u2014 ", label, "."])
end
```

### Option C: Plain-text flash, render coloured badge in view
**Effort:** Medium | **Risk:** Low

Store only plain-text zone info in `@flash_message`. In the Turbo Stream template, render the coloured badge inline using ERB:

```erb
<% if @peak_flow_reading.zone %>
  <p class="flash flash--notice">Reading saved —
    <span class="zone-label zone-label--<%= @peak_flow_reading.zone %>">
      <%= @peak_flow_reading.zone.capitalize %> Zone (<%= @peak_flow_reading.zone_percentage %>% of personal best)
    </span>.
  </p>
<% else %>
  <p class="flash flash--notice"><%= @flash_message %></p>
<% end %>
```

Cleanest separation but requires the Turbo Stream template to have access to `@peak_flow_reading`.

## Recommended Action

Option A — move to helper with `content_tag`. Eliminates the structural risk, makes the method independently testable, follows the convention of keeping HTML generation out of controllers, and produces a `SafeBuffer` that works correctly in both Turbo Stream and HTML redirect paths.

## Technical Details

**Affected files:**
- `app/controllers/peak_flow_readings_controller.rb` (lines 46–54, 21)
- `app/views/peak_flow_readings/create.turbo_stream.erb` (line 15)
- `app/helpers/peak_flow_readings_helper.rb` (new file)

## Acceptance Criteria

- [ ] `zone_flash_message` uses `content_tag` (not string interpolation + `.html_safe`)
- [ ] `raw @flash_message` removed from Turbo Stream view; replaced with `<%= @flash_message %>`
- [ ] HTML redirect path correctly renders the coloured zone badge (not escaped entities)
- [ ] `bin/rails test` passes with 0 failures
- [ ] `bin/brakeman` reports 0 new warnings

## Work Log

- 2026-03-07: Identified by security-sentinel, kieran-rails-reviewer, pattern-recognition-specialist, architecture-strategist in Phase 6 code review
