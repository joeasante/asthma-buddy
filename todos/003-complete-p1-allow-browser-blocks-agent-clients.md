---
status: pending
priority: p1
issue_id: "003"
tags: [code-review, agent-native, architecture, rails]
dependencies: []
---

# `allow_browser versions: :modern` Blocks Non-Browser HTTP Clients

## Problem Statement

`ApplicationController` has `allow_browser versions: :modern` (Rails 8 default). This check rejects requests from non-browser user agents — including `curl`, `faraday`, `net/http`, and any agent SDK HTTP client — with `406 Not Acceptable`. This is a pre-Phase 2 blocker: every future POST endpoint (authentication in Phase 2, symptom recording in Phase 3, etc.) will be inaccessible to agents unless they spoof a browser User-Agent string, which is fragile and incorrect.

## Findings

**Flagged by:** agent-native-reviewer (WARNING — must fix before Phase 2)

**Location:** `app/controllers/application_controller.rb` line 3

```ruby
allow_browser versions: :modern
```

Rails 8's `allow_browser` checks the `User-Agent` header. Any HTTP client that does not identify as a modern browser (Chrome 95+, Safari 15.4+, Firefox 90+, Opera 81+, Edge 95+) receives a 406. Agent tools, API clients, and test HTTP libraries will all hit this wall.

## Proposed Solutions

### Option A — Scope to HTML requests only (Recommended)
Conditionally apply the browser check only when the client is requesting HTML:

```ruby
class ApplicationController < ActionController::Base
  before_action :check_browser_version

  private

  def check_browser_version
    allow_browser versions: :modern if request.format.html?
  end
end
```

**Pros:** Preserves the UX protection for browser users; non-browser clients (agents, API calls) bypass it cleanly.
**Cons:** Slightly less terse than the default.
**Effort:** Small
**Risk:** None

### Option B — Remove `allow_browser` entirely
Delete the `allow_browser versions: :modern` line.

**Pros:** Simplest fix; no special cases.
**Cons:** Removes browser version protection for real users on old browsers.
**Effort:** Trivial
**Risk:** Low (browsers auto-update; old browser warnings are edge cases)

### Option C — Add custom `User-Agent` bypass list
Keep `allow_browser` global but add an exception for known agent UA strings.

**Pros:** Preserves full browser checking.
**Cons:** Brittle — requires maintaining a list; breaks when agent UA strings change.
**Effort:** Medium
**Risk:** Medium

## Recommended Action

Option A — scope `allow_browser` to HTML requests only.

## Technical Details

**Affected files:**
- `app/controllers/application_controller.rb`

**Acceptance Criteria:**
- [ ] Non-browser HTTP clients receive 200 (or appropriate success response) on `GET /`
- [ ] Browser clients on old browsers still receive the `allow_browser` warning page
- [ ] `bin/rails test` passes

## Work Log

- 2026-03-06: Identified by agent-native-reviewer in Foundation Phase code review. Blocking for Phase 2.
