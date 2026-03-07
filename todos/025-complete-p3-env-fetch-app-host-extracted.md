---
status: pending
priority: p3
issue_id: "025"
tags: [code-review, quality, configuration, dry]
dependencies: []
---

# `ENV.fetch("APP_HOST")` Called Twice in production.rb

## Problem Statement

`config/environments/production.rb` calls `ENV.fetch("APP_HOST")` on two separate lines for two different purposes (mailer host and DNS rebinding allowlist). These two settings are always coupled to the same value. As the file grows, additional consumers would proliferate the fetch call, obscuring the relationship.

## Findings

**Flagged by:** kieran-rails-reviewer, architecture-strategist

**Location:** `config/environments/production.rb` lines 62 and 84

```ruby
config.action_mailer.default_url_options = { host: ENV.fetch("APP_HOST") }  # line 62
# ...
config.hosts = [ ENV.fetch("APP_HOST") ]                                     # line 84
```

## Proposed Solutions

### Solution A: Extract to local variable at top of block (Recommended)

```ruby
Rails.application.configure do
  app_host = ENV.fetch("APP_HOST")

  # ...
  config.action_mailer.default_url_options = { host: app_host }
  # ...
  config.hosts = [ app_host ]
end
```
- **Effort:** Tiny
- **Risk:** None

## Recommended Action

Solution A. Trivial change that eliminates the coupling and prevents future proliferation.

## Technical Details

- **Affected file:** `config/environments/production.rb`
- **Lines:** 62 and 84 (or wherever they land after prior edits)

## Acceptance Criteria

- [ ] `ENV.fetch("APP_HOST")` appears exactly once in production.rb
- [ ] Both `config.action_mailer.default_url_options` and `config.hosts` reference the extracted variable
- [ ] `rails test` passes

## Work Log

- 2026-03-06: Identified by kieran-rails-reviewer and architecture-strategist during /ce:review
