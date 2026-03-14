---
status: complete
priority: p2
issue_id: "411"
tags: [code-review, architecture, api, error-handling]
dependencies: []
---

# Replace nil-Return Convention in date_filter with Exception

## Problem Statement

When `date_filter` encounters an invalid date, it renders an error response and returns `nil`. Every calling controller must remember to add `return unless scope` after the call. This is a subtle convention that will be missed as the API grows, causing `NoMethodError` on nil.

## Findings

**Flagged by:** architecture-strategist, kieran-rails-reviewer

**Location:** `app/controllers/api/v1/base_controller.rb`, lines 73-76

```ruby
rescue Date::Error
  render_error(status: 400, message: "Invalid date format. Use YYYY-MM-DD.")
  nil
end
```

All 4 controllers that call `date_filter` have `return unless scope` — correct today but fragile.

## Proposed Solutions

### Option A: Raise custom exception with rescue_from (Recommended)

```ruby
class InvalidDateParam < StandardError; end

rescue_from InvalidDateParam do |e|
  render_error(status: 400, message: e.message)
end

def date_filter(scope, date_column: :recorded_at)
  # ... filtering logic ...
rescue Date::Error
  raise InvalidDateParam, "Invalid date format. Use YYYY-MM-DD."
end
```

Then remove all `return unless scope` guards from resource controllers.

- **Pros:** Eliminates convention dependency, cleaner controllers
- **Cons:** Adds an exception class
- **Effort:** Small (10 min)
- **Risk:** None

## Acceptance Criteria

- [ ] Invalid date returns 400 JSON error
- [ ] No `return unless scope` guards needed in resource controllers
- [ ] All existing tests pass

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-14 | Created from Phase 28 code review | Architecture-strategist flagged |
