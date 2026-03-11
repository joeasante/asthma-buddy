---
status: complete
priority: p2
issue_id: "277"
tags: [code-review, rails, routing, ux]
dependencies: []
---

# Missing redirect from removed `/adherence` route

## Problem Statement

The old route `GET /adherence` (via `AdherenceController`) was deleted and replaced with `GET /preventer_history`. No redirect was added. Any bookmarked URL, any notification that deep-links to `/adherence`, or any document referencing the old URL now returns a 404.

In a medical app where users may have bookmarked health-data pages, a broken route has user trust implications beyond mere inconvenience.

## Findings

- **File:** `config/routes.rb` — `get "preventer_history"` added, `get "adherence"` removed, no `redirect`
- **Agent:** architecture-strategist
- This follows a pattern of silent route removal seen elsewhere in the project — should be standardised

## Proposed Solutions

### Option A — Add a permanent redirect in routes.rb (Recommended)

```ruby
get "adherence", to: redirect("/preventer_history"), status: 301
```

**Pros:** Zero-cost. Handles all clients (browsers, bookmarks, saved links). Idiomatic Rails.
**Effort:** Trivial
**Risk:** None

### Option B — Leave as 404

**Pros:** Fewer routes.
**Cons:** Breaks existing links, confuses users who bookmarked the page.
**Effort:** None
**Risk:** User trust / UX

## Recommended Action

Option A. One line.

## Technical Details

- **Affected file:** `config/routes.rb`

## Acceptance Criteria

- [ ] `GET /adherence` returns 301 redirect to `/preventer_history`
- [ ] Route test or request test verifies the redirect

## Work Log

- 2026-03-11: Identified by architecture-strategist during code review of dev branch
