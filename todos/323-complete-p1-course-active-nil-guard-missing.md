---
status: complete
priority: p1
issue_id: "323"
tags: [code-review, correctness, medications, nil-safety]
dependencies: []
---

# `course_active?` Missing Nil Guard on `ends_on`

## Problem Statement

`app/models/medication.rb#course_active?` does not guard against `ends_on` being `nil`. For medications without an end date (ongoing/indefinite prescriptions), calling `ends_on` returns `nil`, and the comparison `ends_on >= Date.current` raises `NoMethodError: undefined method '>=' for nil`. This crashes any view or logic that calls `course_active?` on an ongoing medication, producing a 500 error.

## Findings

**Flagged by:** kieran-rails-reviewer (rated CRITICAL)

```ruby
# app/models/medication.rb:46 (approx)
def course_active?
  ends_on >= Date.current  # NoMethodError if ends_on is nil
end
```

The fix is a nil guard:
```ruby
def course_active?
  ends_on.nil? || ends_on >= Date.current
end
```

An ongoing medication (no end date) should be considered active indefinitely, so `nil` should return `true`.

## Proposed Solutions

### Option A: Nil guard with `nil?` check (Recommended)
```ruby
def course_active?
  ends_on.nil? || ends_on >= Date.current
end
```

**Pros:** Correct semantics — no end date means indefinitely active
**Cons:** None
**Effort:** Tiny
**Risk:** None

### Option B: Safe navigation with fallback
```ruby
def course_active?
  ends_on&.>=(Date.current) != false
end
```

**Pros:** Terse
**Cons:** Less readable; `!= false` is confusing
**Effort:** Tiny
**Risk:** None

### Recommended Action

Option A — explicit and clear.

## Technical Details

- **File:** `app/models/medication.rb`, `course_active?` method (~line 46)
- `ends_on` is a nullable date column

## Acceptance Criteria

- [ ] `course_active?` returns `true` when `ends_on` is `nil`
- [ ] `course_active?` returns `true` when `ends_on >= Date.current`
- [ ] `course_active?` returns `false` when `ends_on < Date.current`
- [ ] Unit tests cover all three cases

## Work Log

- 2026-03-12: Created from Milestone 2 code review — kieran-rails-reviewer CRITICAL finding
