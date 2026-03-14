---
status: complete
priority: p2
issue_id: "412"
tags: [code-review, rails-conventions, api]
dependencies: []
---

# ApiAuthenticatable Should Use class_methods Block

## Problem Statement

The `ApiAuthenticatable` concern defines a class method using `def self.` inside an `included` block. The idiomatic Rails way is `class_methods do`.

## Findings

**Flagged by:** kieran-rails-reviewer

**Location:** `app/models/concerns/api_authenticatable.rb`, lines 7-13

```ruby
included do
  def self.authenticate_by_api_key(token)
    ...
  end
end
```

## Proposed Solutions

### Option A: Use class_methods block (Recommended)

```ruby
class_methods do
  def authenticate_by_api_key(token)
    return nil if token.blank?
    digest = Digest::SHA256.hexdigest(token)
    find_by(api_key_digest: digest)
  end
end
```

- **Effort:** Small (2 min)
- **Risk:** None

## Acceptance Criteria

- [ ] `authenticate_by_api_key` defined via `class_methods do` block
- [ ] All tests pass

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-14 | Created from Phase 28 code review | Rails convention |
