---
status: pending
priority: p1
issue_id: "090"
tags: [code-review, rails, ux, hotwire, peak-flow]
dependencies: []
---

# `edit.html.erb` hardcodes `has_personal_best: false` — incorrect banner for users who have a personal best

## Problem Statement

`edit.html.erb` and `update_error.turbo_stream.erb` both pass `has_personal_best: false` to the `_form` partial. The `set_has_personal_best` before_action is scoped to `only: %i[new create]` so `@has_personal_best` is never set for `edit` or `update`. Result: a user who *has* set a personal best sees the "Set your personal best" banner every time they open an inline edit form, telling them to do something they already did. In a health tracking app, factually incorrect UI erodes trust.

## Findings

**Flagged by:** kieran-rails-reviewer, security-sentinel, architecture-strategist, pattern-recognition-specialist (consensus P1/P2)

**Location:**
- `app/views/peak_flow_readings/edit.html.erb:2`
- `app/views/peak_flow_readings/update_error.turbo_stream.erb:3`
- `app/controllers/peak_flow_readings_controller.rb:21` (before_action scope)

```ruby
# controller
before_action :set_has_personal_best, only: %i[new create]  # ← edit missing
```

```erb
<%# edit.html.erb %>
<%= render "form", peak_flow_reading: @peak_flow_reading, has_personal_best: false %>
                                                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^
```

```erb
<%# update_error.turbo_stream.erb %>
<%= render "form", peak_flow_reading: @peak_flow_reading, has_personal_best: false %>
```

## Proposed Solutions

### Option A: Extend before_action to include `edit` (Recommended)
Add `:edit` to the existing before_action and pass `@has_personal_best` in both views.

```ruby
before_action :set_has_personal_best, only: %i[new create edit]
```

```erb
<%# edit.html.erb %>
<%= render "form", peak_flow_reading: @peak_flow_reading, has_personal_best: @has_personal_best %>
```

```erb
<%# update_error.turbo_stream.erb %>
<%= turbo_stream.replace dom_id(@peak_flow_reading) do %>
  <%= turbo_frame_tag dom_id(@peak_flow_reading) do %>
    <%= render "form", peak_flow_reading: @peak_flow_reading, has_personal_best: @has_personal_best %>
  <% end %>
<% end %>
```

- **Pros:** Single change to before_action; consistent with how `new` works; `set_has_personal_best` is a simple `exists?` query (fast)
- **Cons:** None
- **Effort:** Small
- **Risk:** None

### Option B: Add deliberate comment if banner suppression is intentional
If the product decision is to never show the banner during inline edit (keep the form compact), add an explicit comment.

```erb
<%# Intentionally false: banner is suppressed during inline edit for compact UX %>
<%= render "form", peak_flow_reading: @peak_flow_reading, has_personal_best: false %>
```

- **Pros:** No code change
- **Cons:** Users who haven't set a personal best also never see the banner during edit — they miss the CTA
- **Effort:** Tiny
- **Risk:** None (documents existing behaviour)

## Recommended Action

Option A — extend the before_action. One-line controller change + two view template updates.

## Technical Details

- **Affected files:** `app/controllers/peak_flow_readings_controller.rb`, `app/views/peak_flow_readings/edit.html.erb`, `app/views/peak_flow_readings/update_error.turbo_stream.erb`
- **Components:** PeakFlowReadingsController, edit flow
- **Database changes:** None

## Acceptance Criteria

- [ ] A user with a personal best set opens the inline edit form — banner does NOT appear
- [ ] A user without a personal best opens the inline edit form — banner DOES appear
- [ ] Existing tests pass (170 tests, 0 failures)
- [ ] Add a controller test for `GET /peak-flow-readings/:id/edit` asserting no banner for a user with personal best

## Work Log

- 2026-03-07: Identified during Phase 7 code review by kieran-rails-reviewer, security-sentinel, architecture-strategist, pattern-recognition-specialist
