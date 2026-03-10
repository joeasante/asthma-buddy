---
status: pending
priority: p3
issue_id: "230"
tags: [code-review, rails, simplification]
dependencies: []
---

# `set_cookie_notice_flag` before_action assigns ivar on JSON/non-HTML requests

## Problem Statement

`set_cookie_notice_flag` in `ApplicationController` runs on every request including JSON API calls, Turbo frame requests, and `head :no_content` responses. The `@show_cookie_notice` ivar is set even when it will never be used (layout is not rendered for JSON). This is semantically noisy — the existing `allow_browser` call in the same controller is already correctly gated with `if request.format.html?`. A simpler alternative is to inline the session check directly in the layout partial, eliminating the before_action, method, and ivar entirely.

## Findings

**Flagged by:** phase-16-code-reviewer

**Location:** `app/controllers/application_controller.rb`, `app/views/layouts/application.html.erb`

## Proposed Solutions

### Option A (Recommended) — Inline the session check in the layout

Remove `before_action :set_cookie_notice_flag` and the private method. In `application.html.erb`, change:

```erb
render "layouts/cookie_notice" if @show_cookie_notice
```

to:

```erb
render "layouts/cookie_notice" unless session[:cookie_notice_shown]
```

**Effort:** Trivial — 5 lines removed, zero behaviour change
**Risk:** None

### Option B — Guard the before_action method body

Add an `if request.format.html?` guard to the method body, matching the `allow_browser` pattern already in the same controller:

```ruby
def set_cookie_notice_flag
  return unless request.format.html?
  @show_cookie_notice = !session[:cookie_notice_shown]
end
```

**Effort:** Trivial
**Risk:** None

## Recommended Action

Option A. Inlining the check eliminates the ivar, the method, and the before_action registration entirely. The layout is only rendered for HTML responses by definition, so the check is always correct there.

## Technical Details

**Acceptance Criteria:**
- [ ] Cookie notice still renders correctly for first-time visitors
- [ ] No ivar assigned on JSON/non-HTML requests

## Work Log

- 2026-03-10: Identified by phase-16-code-reviewer.
