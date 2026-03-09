---
status: pending
priority: p2
issue_id: "114"
tags: [code-review, rails, quality, ruby, profiles]
dependencies: []
---

# `render :show, status: :unprocessable_entity and return` — wrong Ruby idiom

## Problem Statement

The `and` operator has very low precedence in Ruby — lower than method calls. `render ... and return` is parsed as `(render ...) and (return)`, which works accidentally but is not the Rails convention and misleads readers into thinking `and` is part of the render call. All other Rails controllers use `return render ...`.

## Findings

- `app/controllers/profiles_controller.rb:27` — `render :show, status: :unprocessable_entity and return`
- Rails convention (and every other controller in this codebase): `return render :show, status: :unprocessable_entity`

## Proposed Solutions

### Option A: Replace with correct idiom
```ruby
return render :show, status: :unprocessable_entity
```
**Effort:** Small | **Risk:** Low

## Recommended Action

Option A.

## Technical Details

- **Affected file:** `app/controllers/profiles_controller.rb:27`

## Acceptance Criteria

- [ ] `and return` replaced with `return render`
- [ ] No other `and return` anti-patterns introduced

## Work Log

- 2026-03-08: Identified by kieran-rails-reviewer and pattern-recognition-specialist
