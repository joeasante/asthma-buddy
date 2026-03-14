---
status: pending
priority: p2
issue_id: "381"
tags: [code-review, security, rails]
dependencies: []
---

## Problem Statement
`SiteSetting.toggle_registration!` reads current value, computes opposite, then writes — not atomic. Two concurrent calls could both read "true", both write "false", resulting in no-op instead of double-toggle. Low risk (admin-only, unlikely concurrent) but trivial to fix.

## Findings
- `toggle_registration!` performs a read-then-write pattern
- Not wrapped in a transaction or using atomic SQL
- Concurrent calls could produce incorrect results

## Proposed Solutions
### Option A: Use atomic SQL UPDATE
Replace the read-then-write with a single atomic UPDATE statement:
`UPDATE site_settings SET value = CASE WHEN value = 'true' THEN 'false' ELSE 'true' END WHERE key = 'registration_open'`

**Pros:** Atomic, one-liner.
**Effort:** Small.
**Risk:** Low.

## Acceptance Criteria
- [ ] `toggle_registration!` uses a single UPDATE statement
- [ ] No read-then-write pattern remains
