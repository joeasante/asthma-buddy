---
status: pending
priority: p2
issue_id: "024"
tags: [code-review, testing, configuration, solid-cache]
dependencies: []
---

# `cache.yml` Test Environment Inherits 60-Day `max_age` from Default

## Problem Statement

`config/cache.yml` enables `max_age: 60.days.to_i` in the `default:` anchor, which is inherited by the `test:` stanza. If Solid Cache is the active store in the test environment, cached test data could persist across test runs for up to 60 days, causing hard-to-reproduce test failures from stale cached values.

## Findings

**Flagged by:** kieran-rails-reviewer

**Location:** `config/cache.yml`

```yaml
default: &default
  store_options:
    max_age: <%= 60.days.to_i %>   # ← inherited by test: stanza
    max_size: <%= 256.megabytes %>
    namespace: <%= Rails.env %>

test:
  <<: *default                     # ← no override for max_age
```

**Key question:** Is `config.cache_store = :solid_cache_store` set in `config/environments/test.rb`?

If yes: the 60-day max_age applies in tests — stale cache entries can bleed between test runs.
If no (default Rails test uses `:memory_store` or `:null_store`): the setting is a no-op in test but still misleading.

Either way, the test stanza should explicitly handle the max_age — either by overriding it to a short TTL or by documenting that Solid Cache is not used in tests.

## Proposed Solutions

### Solution A: Override max_age in the test stanza (Recommended if Solid Cache is used in test)
```yaml
test:
  <<: *default
  store_options:
    max_age: <%= 5.minutes.to_i %>
    max_size: <%= 256.megabytes %>
    namespace: <%= Rails.env %>
```
- **Pros:** Prevents long-lived cache entries from persisting across test runs.
- **Effort:** Small
- **Risk:** None

### Solution B: Add a comment documenting that Solid Cache is not used in test
```yaml
test:
  <<: *default
  # Note: :solid_cache_store is not set in config/environments/test.rb —
  # this stanza is inherited but store_options are ignored when using :memory_store.
```
- **Pros:** Clarifies intent without code change.
- **Cons:** Fragile — if someone adds Solid Cache to test environment later, the 60-day max_age silently kicks in.
- **Effort:** Tiny
- **Risk:** Low

## Recommended Action

First, check `config/environments/test.rb` for `cache_store` configuration. If Solid Cache is not the test store, Solution B is sufficient. If it is (or might be), Solution A.

## Technical Details

- **Affected file:** `config/cache.yml`
- **Check first:** `grep -n "cache_store" config/environments/test.rb`

## Acceptance Criteria

- [ ] `config/environments/test.rb` cache store configuration reviewed
- [ ] If Solid Cache is test store: `max_age` overridden to ≤5 minutes in `test:` stanza
- [ ] If not Solid Cache: comment added documenting this
- [ ] `rails test` passes

## Work Log

- 2026-03-06: Identified by kieran-rails-reviewer during /ce:review of foundation phase changes
