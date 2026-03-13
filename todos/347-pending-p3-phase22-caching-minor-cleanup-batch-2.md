---
status: pending
priority: p3
issue_id: "347"
tags: [code-review, caching, cleanup, rails, testing]
dependencies: ["343", "344", "345"]
---

# Phase 22 caching minor cleanup batch 2

## Problem Statement

Several small code-quality and consistency issues identified in the second Phase 22 code review. None are correctness bugs; all are readability or resilience improvements.

## Findings

### 1. DoseLog mixes after_create_commit shorthand with after_commit longhand in same file
**File:** `app/models/dose_log.rb:15-17`
```ruby
after_create_commit :check_low_stock
after_commit -> { invalidate_dashboard_cache }, on: :create
after_commit -> { invalidate_dashboard_cache }, on: :destroy
```
The file uses the shorthand `after_create_commit` for one callback and the longhand `after_commit ... on: :create` form for another on the same lifecycle event. Both are correct but inconsistent within the file. Once todo 343 is resolved (extracting `invalidate_dashboard_cache` to a concern), the lambda callbacks can be standardised.

### 2. status: stored as Ruby symbol — breaks if cache store ever switches to JSON
**File:** `app/controllers/concerns/dashboard_variables.rb:39`, `app/views/dashboard/_today_doses_list.html.erb:2`
The cache stores `status: result.status` which is a Ruby symbol (`:on_track`, `:pending`, etc.). `Solid Cache` uses `Marshal`, which preserves symbols. However `_today_doses_list.html.erb` compares `e[:status] == :on_track`. If the cache store ever changes to a JSON-serializing backend, symbols would be deserialized as strings and this comparison would silently fail (always false).

Low probability with the current SQLite-backed Solid Cache, but worth a comment or a `to_sym` guard.

### 3. No solution document for Solid Cache + after_commit pattern
The Phase 22 work established a new caching pattern (Solid Cache, after_commit invalidation, cache key class methods, plain hash storage). This pattern will be repeated in future phases. A solution document in `docs/solutions/` would prevent future developers from re-solving the same decisions.

Suggested: create `docs/solutions/solid-cache-after-commit-invalidation.md` documenting:
- Why lambda form vs symbol form for callbacks
- Why top-level test classes are needed for use_transactional_tests = false
- The plain hash vs AR object decision and its tradeoffs
- Cache key design pattern (class method on owning model/concern)

## Proposed Solutions

Fix all items as a batch:

### Item 1
Defer until todo 343 is resolved — the concern extraction will naturally standardise the callbacks.

### Item 2
Option A: Add `.to_sym` in the view: `e[:status].to_sym == :on_track`
Option B: Add a comment in `dashboard_variables.rb` noting the Marshal dependency: "status is stored as a Ruby symbol — requires a Marshal-preserving cache store (Solid Cache / MemoryStore)"

### Item 3
Create the solution document after 343, 344, 345 are resolved (so it documents the final state).

## Acceptance Criteria

- [ ] DoseLog callback style inconsistency noted and resolved (after 343)
- [ ] `status` symbol safety documented or guarded
- [ ] `docs/solutions/solid-cache-after-commit-invalidation.md` created

## Work Log

- 2026-03-13: Identified in Phase 22 second code review (kieran-rails-reviewer, pattern-recognition-specialist, learnings-researcher)
