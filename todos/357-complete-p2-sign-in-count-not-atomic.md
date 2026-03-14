---
status: complete
priority: p2
issue_id: 357
tags: [code-review, database, correctness]
dependencies: []
---

## Problem Statement

`update_columns(sign_in_count: user.sign_in_count + 1)` reads the count in Ruby and writes back. Concurrent logins could lose an increment.

## Findings

In `app/controllers/sessions_controller.rb`, the sign-in count is incremented by reading the current value in Ruby (`user.sign_in_count`), adding 1, and writing it back with `update_columns`. If two concurrent login requests read the same value before either writes, one increment is lost. While this is a display counter and not security-critical, it is a correctness issue that is trivial to fix.

## Proposed Solutions

**A) Use `User.where(id: user.id).update_all("sign_in_count = sign_in_count + 1")` for atomic SQL increment**
- Pros: Correct under concurrency; single SQL statement; no Ruby read needed
- Cons: Slightly different API than `update_columns`; need to reload if the value is used after

**B) Accept the race as non-critical for a display counter**
- Pros: No code change
- Cons: Known incorrect behavior; sets a bad pattern for future counters

## Recommended Action



## Technical Details

**Affected files:**
- `app/controllers/sessions_controller.rb`

## Acceptance Criteria

- [ ] sign_in_count uses atomic SQL increment
- [ ] No lost increments under concurrent login
