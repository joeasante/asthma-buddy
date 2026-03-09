---
title: Turbo Stream Flash Messages and Frame Preservation
slug: turbo-stream-flash-messages-and-frame-preservation
date: 2026-03-07
problem_type: ui_bug
component: peak_flow_readings
severity: high
tags:
  - hotwire
  - turbo-stream
  - turbo-frame
  - xss
  - flash-messages
  - html-safe
  - rails
related_files:
  - app/helpers/peak_flow_readings_helper.rb
  - app/controllers/peak_flow_readings_controller.rb
  - app/views/peak_flow_readings/create.turbo_stream.erb
  - app/views/peak_flow_readings/form_error.turbo_stream.erb
related_docs:
  - docs/solutions/ui-bugs/hotwire-turbo-stream-form-validation-issues.md
status: solved
---

# Turbo Stream Flash Messages and Frame Preservation

## Problem Statement

Two structural bugs were identified during code review of the peak flow reading feature:

1. **XSS structural risk**: Flash messages were built via string interpolation and marked `html_safe`, then stored in the Rails flash or an instance variable and rendered with `raw` in the Turbo Stream template.
2. **Turbo frame silently destroyed on validation error**: A `turbo_stream.replace` targeting a DOM element that contained a `<turbo-frame>` did not include `turbo_frame_tag` in the replacement — causing the frame to vanish from the DOM, silently breaking all subsequent form submissions.

### Observable Symptoms

**Bug 1 (XSS / html_safe):**
- Flash message worked visually, but zone label was produced by unsafe string interpolation.
- `"Reading saved — #{zone.capitalize} Zone".html_safe` creates a `SafeBuffer`, but if this value is stored in the Rails `flash` hash and the user is redirected, it is serialized to the session and deserialized back as a plain `String`, losing its `SafeBuffer` status and XSS safety guarantees.
- Even when not stored in flash, `raw @flash_message` bypasses Rails' auto-escaping — any user-controlled data in the zone label would execute as HTML.

**Bug 2 (Turbo frame destruction):**
- On validation error, the form was re-rendered via `turbo_stream.replace "peak_flow_reading_form"` without a wrapping `turbo_frame_tag`.
- The original DOM had a `<turbo-frame id="peak_flow_reading_form">` element.
- After the replace, the DOM element became a plain `<div>` — the `<turbo-frame>` element was gone.
- All future form submissions hit the regular Rails response path instead of the Turbo Stream path, breaking the SPA-style UX silently (no JS error, no visible failure).

---

## Root Cause Analysis

### Bug 1: SafeBuffer does not survive session serialization

Rails auto-escapes `String` values in ERB but skips escaping for `ActiveSupport::SafeBuffer` (the type returned by `.html_safe`). When you call `.html_safe` on a string and immediately render it in a view, escaping is safely bypassed. However:

- If the `SafeBuffer` is stored in the `flash` hash and the user is redirected, Rails serializes the flash to the session cookie (or database session), converting it to a plain `String`.
- On the next request, the value is deserialized as a plain `String` — no longer a `SafeBuffer`.
- Any downstream `raw flash[:notice]` now outputs an unescaped plain `String`, creating an XSS vector if the value contains user-controlled data.

The fix: build HTML-safe flash content in a **helper** using `content_tag` and `safe_join`, which Rails designed for exactly this purpose. Never store `html_safe` strings in the flash hash or cross a request boundary.

### Bug 2: turbo_stream.replace must preserve the turbo-frame element

`turbo_stream.replace "some_id"` replaces the entire element with the given ID. If the original DOM element was a `<turbo-frame id="some_id">`, the replacement must also be a `<turbo-frame>` — otherwise the frame is destroyed and Turbo's client-side routing for that frame breaks permanently for the session.

The fix: always wrap the re-rendered content in `turbo_frame_tag` when replacing a target that is a turbo frame.

---

## Working Solution

### Fix 1: Move flash message construction to a helper

**`app/helpers/peak_flow_readings_helper.rb`** (new file):

```ruby
# frozen_string_literal: true
module PeakFlowReadingsHelper
  # Returns an HTML-safe flash message with a coloured zone label.
  # Uses content_tag + safe_join — never raw string interpolation.
  # Do NOT store the return value in the Rails flash hash; it is rendered
  # directly via @flash_message in the Turbo Stream template.
  def zone_flash_message(reading)
    return "Reading saved \u2014 set your personal best to see your zone." if reading.zone.nil?

    label = content_tag(:span,
                        "#{reading.zone.capitalize} Zone (#{reading.zone_percentage}% of personal best)",
                        class: "zone-label zone-label--#{reading.zone}")
    safe_join([ "Reading saved \u2014 ", label, "." ])
  end

  # Plain-text version for HTML redirects (stored in flash — no HTML, safe to serialize).
  def zone_flash_message_text(reading)
    return "Reading saved \u2014 set your personal best to see your zone." if reading.zone.nil?

    "Reading saved \u2014 #{reading.zone.capitalize} Zone (#{reading.zone_percentage}% of personal best)."
  end
end
```

**Controller** (`app/controllers/peak_flow_readings_controller.rb`):

```ruby
def create
  @peak_flow_reading = Current.user.peak_flow_readings.new(peak_flow_reading_params)
  if @peak_flow_reading.save
    @flash_message = helpers.zone_flash_message(@peak_flow_reading)
    @new_peak_flow_reading = Current.user.peak_flow_readings.new(recorded_at: Time.current.change(sec: 0))
    respond_to do |format|
      format.turbo_stream                        # renders create.turbo_stream.erb
      format.html { redirect_to new_peak_flow_reading_path, notice: helpers.zone_flash_message_text(@peak_flow_reading) }
      format.json { render json: peak_flow_reading_json(@peak_flow_reading), status: :created }
    end
  else
    respond_to do |format|
      format.turbo_stream { render :form_error, status: :unprocessable_entity }
      format.html { render :new, status: :unprocessable_entity }
      format.json { render json: { errors: @peak_flow_reading.errors.full_messages }, status: :unprocessable_entity }
    end
  end
end
```

**Turbo Stream template** (`app/views/peak_flow_readings/create.turbo_stream.erb`):

```erb
<%# @flash_message is an HTML-safe SafeBuffer produced by helpers.zone_flash_message %>
<%# Do NOT use raw — ERB auto-escaping is safe to disable via SafeBuffer, but raw bypasses it unconditionally %>
<%= turbo_stream.replace "peak_flow_reading_form" do %>
  <%= turbo_frame_tag "peak_flow_reading_form" do %>
    <%= render "form", peak_flow_reading: @new_peak_flow_reading, has_personal_best: @has_personal_best %>
  <% end %>
<% end %>

<%= turbo_stream.replace "flash-messages" do %>
  <div id="flash-messages">
    <p role="status" class="flash flash--notice"><%= @flash_message %></p>
  </div>
<% end %>
```

Key point: `<%= @flash_message %>` (not `raw`) — ERB's `<<` uses `to_s`, which preserves the `SafeBuffer` type, so auto-escaping is correctly bypassed.

### Fix 2: Preserve the turbo-frame on validation error

Create a dedicated validation error template (`app/views/peak_flow_readings/form_error.turbo_stream.erb`):

```erb
<%# Validation error — wrap partial in turbo_frame_tag so the frame element persists in DOM %>
<%= turbo_stream.replace "peak_flow_reading_form" do %>
  <%= turbo_frame_tag "peak_flow_reading_form" do %>
    <%= render "form",
          peak_flow_reading: @peak_flow_reading,
          has_personal_best: @has_personal_best %>
  <% end %>
<% end %>
```

The controller renders this explicitly on the error path:

```ruby
format.turbo_stream { render :form_error, status: :unprocessable_entity }
```

**Why a separate template?** The success path (`create.turbo_stream.erb`) renders a blank new form (`@new_peak_flow_reading`) plus a flash message. The error path renders the submitted form (`@peak_flow_reading`) with validation errors and no flash. A single template would require conditionals that obscure intent.

---

## Prevention Strategies

### Rules of thumb

1. **Never call `.html_safe` on a string containing dynamic data** — use `content_tag`, `tag.`, or `safe_join` instead. These methods escape interpolated values automatically.
2. **Never store `html_safe` strings in the Rails flash hash** — `SafeBuffer` does not survive session serialization. Use plain text in flash, build HTML in the view or helper.
3. **Never use `raw` in views** — use `<%= value %>` which is safe when `value` is a `SafeBuffer`, and use `content_tag`/`safe_join` to produce `SafeBuffer` values.
4. **When replacing a `<turbo-frame>` via `turbo_stream.replace`, always wrap the replacement in `turbo_frame_tag`** — otherwise the frame is removed from the DOM permanently.
5. **Test the validation error path explicitly** — it is easy to test the happy path and miss that the form breaks after a validation failure.

### Code review checklist

- [ ] Does any view call `raw`, `.html_safe`, or `html_safe` on a value containing user data or dynamic content?
- [ ] Are any `SafeBuffer`/`html_safe` values stored in `flash[:notice]` or `flash[:alert]`?
- [ ] For every `turbo_stream.replace` targeting a turbo-frame, does the replacement include `turbo_frame_tag`?
- [ ] Is there a separate Turbo Stream template for the validation error path?
- [ ] Does the controller pass `@new_peak_flow_reading` (a blank record) to the success Turbo Stream template rather than calling `.new` in the view?

### Anti-patterns to avoid

```ruby
# ❌ XSS risk — dynamic data marked html_safe
@flash_message = "Saved — #{zone.capitalize} Zone".html_safe

# ❌ Unsafe rendering — bypasses auto-escaping unconditionally
<%= raw @flash_message %>

# ❌ SafeBuffer lost in session serialization
flash[:notice] = "Saved — <strong>#{zone}</strong>".html_safe

# ❌ Turbo frame silently destroyed
turbo_stream.replace "my_frame" do
  render partial: "my_form"   # no turbo_frame_tag — frame disappears
end
```

```ruby
# ✅ Safe — content_tag escapes zone automatically
label = content_tag(:span, "#{zone.capitalize} Zone", class: "zone-label")
safe_join(["Saved — ", label, "."])

# ✅ Safe rendering — SafeBuffer bypasses escaping correctly
<%= @flash_message %>

# ✅ Plain text in flash (safe to serialize)
flash[:notice] = "Saved — #{zone.capitalize} Zone (#{pct}% of personal best)."

# ✅ Frame preserved on replace
turbo_stream.replace "my_frame" do
  turbo_frame_tag "my_frame" do
    render partial: "my_form"
  end
end
```

### Test cases to add

```ruby
# Test: zone label is properly escaped in Turbo Stream response
test "create with zone renders escaped zone label" do
  post peak_flow_readings_url, params: { peak_flow_reading: { value: 400, recorded_at: Time.current } },
                                as: :turbo_stream
  assert_response :ok
  # flash-messages div must not contain raw HTML injected via string interpolation
  assert_select "p.flash--notice span.zone-label"
end

# Test: turbo-frame persists after validation error
test "create with invalid value preserves turbo frame" do
  post peak_flow_readings_url, params: { peak_flow_reading: { value: "", recorded_at: Time.current } },
                                as: :turbo_stream
  assert_response :unprocessable_entity
  # frame must be present so subsequent submissions work
  assert_select "turbo-frame#peak_flow_reading_form"
end

# Test: second submission after validation error still works
test "form remains functional after validation error" do
  post peak_flow_readings_url, params: { peak_flow_reading: { value: "", recorded_at: Time.current } },
                                as: :turbo_stream
  assert_response :unprocessable_entity

  post peak_flow_readings_url, params: { peak_flow_reading: { value: 400, recorded_at: Time.current } },
                                as: :turbo_stream
  assert_response :ok
  assert PeakFlowReading.last.value == 400
end
```

---

## Related Issues

- [`docs/solutions/ui-bugs/hotwire-turbo-stream-form-validation-issues.md`](hotwire-turbo-stream-form-validation-issues.md) — General Turbo Stream form validation patterns; does not cover frame preservation or flash XSS.
- These two bugs commonly appear together: Turbo Stream flash messages need HTML, which tempts developers to use `html_safe`; and validation error paths are an afterthought that often omit `turbo_frame_tag`.

---

## Key Takeaways

- **`content_tag` and `safe_join` are the only safe ways to produce HTML-safe strings from dynamic data in Rails.** String interpolation + `.html_safe` is always risky.
- **The Rails flash hash is a plain Ruby hash serialized to a cookie/session.** It cannot safely carry `SafeBuffer` values across a redirect. Use plain text in flash; build styled HTML in helpers and render it directly into Turbo Stream responses.
- **Turbo Streams replace DOM elements, not their children.** If the target is a `<turbo-frame>`, the replacement must also be a `<turbo-frame>` or the frame is gone.
- **Always test validation error paths in Turbo Stream contexts.** The failure mode (silently broken form) has no visible JS error, making it easy to miss in manual testing.
