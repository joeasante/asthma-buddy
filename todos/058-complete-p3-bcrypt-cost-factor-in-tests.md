---
status: pending
priority: p3
issue_id: "058"
tags: [code-review, performance, testing]
dependencies: []
---

# BCrypt Default Cost Factor Slows Down Test Suite — Use `MIN_COST` in Test Environment

## Problem Statement

`test/fixtures/users.yml` generates password digests via `BCrypt::Password.create("password123")`, which uses the default bcrypt cost factor (10). BCrypt is intentionally slow. As the test suite grows and more tests load fixtures or call `User.authenticate_by`, bcrypt's intentional slowness adds measurable wall clock time.

## Findings

**Flagged by:** kieran-rails-reviewer (LOW)

**Location:** `test/fixtures/users.yml`

```yaml
password_digest: <%= BCrypt::Password.create("password123") %>
```

This runs at every test load. With `parallelize(workers: :number_of_processors)` and multiple fixture-loading test files, this compounds.

## Proposed Solution

Add to `test/test_helper.rb`:

```ruby
BCrypt::Engine.cost = BCrypt::Engine::MIN_COST
```

`MIN_COST` is 4 (vs default 10), reducing per-hash time from ~100ms to <1ms. This is a standard Rails optimization used by many teams.

- **Effort:** Tiny (1 line)
- **Risk:** None — only affects test environment, `MIN_COST` is a BCrypt constant

## Acceptance Criteria

- [ ] `test/test_helper.rb` sets `BCrypt::Engine.cost = BCrypt::Engine::MIN_COST`
- [ ] Test suite runs faster (measurable with `time bin/rails test`)
- [ ] All existing auth tests still pass

## Work Log

- 2026-03-07: Created from Rails review. kieran-rails-reviewer LOW.
