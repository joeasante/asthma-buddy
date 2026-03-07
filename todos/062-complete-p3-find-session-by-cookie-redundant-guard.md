---
status: pending
priority: p3
issue_id: "062"
tags: [code-review, simplicity, quality]
dependencies: []
---

# `find_session_by_cookie` Has Redundant Nil Guard — `Session.find_by(id: nil)` Is Already Safe

## Problem Statement

`find_session_by_cookie` reads `cookies.signed[:session_id]` twice: once to check if it's present, and once to pass to `find_by`. `Session.find_by(id: nil)` returns nil safely, making the guard unnecessary.

## Findings

**Flagged by:** code-simplicity-reviewer (Simplification #2)

**Location:** `app/controllers/concerns/authentication.rb:29-31`

```ruby
def find_session_by_cookie
  Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
  # cookies.signed[:session_id] read TWICE — once for guard, once for query
end
```

`Session.find_by(id: nil)` → returns `nil`. The guard is defensive with no benefit.

## Proposed Solution

```ruby
def find_session_by_cookie
  Session.find_by(id: cookies.signed[:session_id])
end
```

One less cookie read, one less line of code.

- **Effort:** Tiny
- **Risk:** None — behavior is identical

## Acceptance Criteria

- [ ] `find_session_by_cookie` reads `cookies.signed[:session_id]` exactly once
- [ ] All session-related tests pass

## Work Log

- 2026-03-07: Created from simplicity review. code-simplicity-reviewer.
