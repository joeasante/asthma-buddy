---
status: pending
priority: p2
issue_id: "095"
tags: [code-review, rails, security, peak-flow]
dependencies: []
---

# `@active_preset` not validated — arbitrary values flow into URL generation and CSS logic

## Problem Statement

`@active_preset` is set directly from `params[:preset]` without validation against the allowed set. The value flows into `_filter_bar.html.erb` (CSS class conditional), `_pagination.html.erb` (URL query params), and the date range `case` statement. A value like `"../admin"` or a very long string won't cause a security issue due to HTML encoding, but an unrecognised preset silently falls through the `case` to `nil` — the user gets the full-history range via `Time.at(0)` rather than an error, and no filter chip shows as active.

## Findings

**Flagged by:** kieran-rails-reviewer

**Location:** `app/controllers/peak_flow_readings_controller.rb:31`

```ruby
@active_preset = params[:preset].presence || "30"
```

Unrecognised presets fall through `case` to `else nil`, while `Time.at(0)` lower bound applies. Pagination links propagate the unrecognised value through query strings indefinitely.

## Proposed Solutions

### Option A: Add an allowlist constant (Recommended)

```ruby
ALLOWED_PRESETS = %w[7 30 90 all custom].freeze

def index
  @active_preset = ALLOWED_PRESETS.include?(params[:preset]) ? params[:preset] : "30"
  # ...
end
```

- **Pros:** Self-documenting; prevents unexpected values; one line
- **Effort:** Tiny
- **Risk:** None

### Option B: Validate via case-else with explicit fallback

The existing `case` statement already handles known values; add a guard before it:

```ruby
preset = params[:preset].presence
@active_preset = %w[7 30 90 all custom].include?(preset) ? preset : "30"
```

- **Effort:** Tiny
- **Risk:** None

## Recommended Action

Option A — define `ALLOWED_PRESETS` constant at the controller class level for visibility.

## Technical Details

- **Affected files:** `app/controllers/peak_flow_readings_controller.rb`

## Acceptance Criteria

- [ ] `?preset=anything-weird` defaults to 30-day filter
- [ ] Valid preset values (`7`, `30`, `90`, `all`, `custom`) still work
- [ ] Constant `ALLOWED_PRESETS` is defined and used

## Work Log

- 2026-03-07: Identified during Phase 7 code review
