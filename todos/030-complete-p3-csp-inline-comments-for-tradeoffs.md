---
status: pending
priority: p3
issue_id: "030"
tags: [code-review, quality, csp, documentation]
dependencies: [021]
---

# CSP and SQLite WAL Config Missing Inline Comments for Non-Obvious Trade-offs

## Problem Statement

Two configuration files have important trade-offs that are not documented inline, creating a risk that future maintainers will change them without understanding the implications:

1. `content_security_policy.rb`: `style_src :self, :unsafe_inline` (after removing it per todo 021, note why it's gone) and the `report_only = true` transition path are undocumented.
2. `database_wal.rb`: `synchronous=NORMAL` is safe with WAL but not against hard power failure — this trade-off should be documented.

## Findings

**Flagged by:** kieran-rails-reviewer, performance-oracle, architecture-strategist, pattern-recognition-specialist

**Locations:**

`config/initializers/content_security_policy.rb`:
```ruby
# Missing: comment on report_only transition criteria
config.content_security_policy_report_only = true
```

`config/initializers/database_wal.rb`:
```ruby
# Missing: explanation of NORMAL vs FULL trade-off
execute("PRAGMA synchronous=NORMAL;")
```

## Proposed Solutions

### Solution A: Add targeted inline comments

**content_security_policy.rb** — add after `report_only = true`:
```ruby
# Report-only mode: violations are reported but not blocked. Switch to enforcing
# (set to false) after: fixing the nonce generator (todo 018), removing unsafe_inline
# (todo 021), adding report-uri (todo 021), and observing zero violations in production.
config.content_security_policy_report_only = true
```

**database_wal.rb** — add before the synchronous PRAGMA:
```ruby
# NORMAL is 2-3x faster than FULL and safe against application and OS crashes with WAL.
# Trade-off: a hard power failure between WAL write and checkpoint could lose the last
# checkpoint interval of committed transactions (~< 1 second). Acceptable for a
# single-server cloud VM in a datacenter with redundant power.
execute("PRAGMA synchronous=NORMAL;")
```
- **Effort:** Tiny
- **Risk:** None

## Recommended Action

Solution A. Small comments, high long-term value.

## Technical Details

- **Affected files:** `config/initializers/content_security_policy.rb`, `config/initializers/database_wal.rb`

## Acceptance Criteria

- [ ] `report_only = true` has comment explaining transition criteria
- [ ] `synchronous=NORMAL` has comment explaining the durability trade-off
- [ ] Comments reference relevant todos/tickets for the enforcement transition
- [ ] `rails test` passes

## Work Log

- 2026-03-06: Identified by multiple agents during /ce:review of foundation phase changes
