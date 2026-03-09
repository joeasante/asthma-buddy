---
status: pending
priority: p3
issue_id: "157"
tags: [code-review, rails, lexxy, health-events]
dependencies: []
---

# `toolbar: "false"` Is a Truthy String, Not a Boolean

## Problem Statement

`app/views/health_events/_form.html.erb` passes `toolbar: "false"` (a string) to `form.rich_text_area`. The string `"false"` is truthy in Ruby. If Lexxy interprets this as a boolean option, `"false"` will behave as `true`. The intent is to disable the toolbar, but the mechanism is wrong.

## Findings

**Flagged by:** kieran-rails-reviewer (P2)

**Location:** `app/views/health_events/_form.html.erb`, rich_text_area call

**Current code:**
```erb
<%= form.rich_text_area :notes,
      toolbar: "false",
      aria: { ... },
      placeholder: "..." %>
```

**Issue:** `"false"` is a non-empty string — it is truthy in Ruby/ERB. The equivalent in `symptom_logs/_form.html.erb` should be checked for consistency.

## Proposed Solutions

### Option A — Use boolean `false` (Recommended)
```erb
<%= form.rich_text_area :notes,
      toolbar: false,
      ...
```

**Effort:** Trivial
**Risk:** None (Lexxy uses `false` to disable the toolbar)

### Option B — Remove the option entirely if Lexxy defaults to no toolbar
Check Lexxy docs — if the toolbar is hidden by default, removing the option is simpler.

## Acceptance Criteria

- [ ] `toolbar: false` (boolean) in `_form.html.erb`
- [ ] Rich text area renders without toolbar in browser

## Work Log

- 2026-03-09: Identified by kieran-rails-reviewer during `ce:review`.
