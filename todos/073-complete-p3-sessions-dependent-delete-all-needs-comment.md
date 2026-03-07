---
status: pending
priority: p3
issue_id: "073"
tags: [code-review, rails, quality]
dependencies: []
---

# `has_many :sessions, dependent: :delete_all` — Silent Behaviour Change Needs Explanatory Comment

## Problem Statement

The Phase 6 diff silently changed `has_many :sessions, dependent: :destroy` to `dependent: :delete_all`. This skips ActiveRecord callbacks on session deletion. It's likely correct today (sessions have no meaningful destroy callbacks), but the reasoning is not documented. A future developer who adds a `before_destroy` or `after_destroy` callback to `Session` will be surprised to find it never fires.

## Findings

**Flagged by:** kieran-rails-reviewer

**Location:** `app/models/user.rb`

```ruby
# Before (implicit in git history)
has_many :sessions, dependent: :destroy

# After (current)
has_many :sessions, dependent: :delete_all
```

`delete_all` issues a single SQL `DELETE WHERE user_id = ?` — no Ruby objects loaded, no callbacks fired. `:destroy` loads each record and fires callbacks. For sessions, `delete_all` is the right choice for performance (a user may have many sessions), but this intent should be commented.

## Proposed Solution

Add an inline comment:

```ruby
# :delete_all instead of :destroy — sessions have no callbacks and a user may have many.
# A bulk DELETE is more efficient than loading and destroying each record individually.
has_many :sessions, dependent: :delete_all
```

**Effort:** XSmall (1 comment)
**Risk:** Zero

## Acceptance Criteria

- [ ] Comment added explaining the `delete_all` choice
- [ ] All tests still pass

## Work Log

- 2026-03-07: Identified by kieran-rails-reviewer during Phase 6 code review
