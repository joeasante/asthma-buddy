---
status: pending
priority: p2
issue_id: 422
tags: [code-review, api, input-validation]
dependencies: []
---

# Date.parse accepts ambiguous formats despite YYYY-MM-DD error message

## Problem Statement

The `date_filter` method in `Api::V1::BaseController` uses `Date.parse` which accepts many formats (`14/03/2026`, `March 14, 2026`, etc.) but the error message says "Use YYYY-MM-DD". The API documentation implies strict ISO 8601 but the code does not enforce it.

## Findings

- **Source**: kieran-rails-reviewer (Finding #7)
- **Location**: `app/controllers/api/v1/base_controller.rb:72-84`

## Proposed Solutions

### Option A: Use Date.strptime with strict format
- **Approach**: Replace `Date.parse` with `Date.strptime(params[:date_from], "%Y-%m-%d")`
- **Effort**: Small
- **Risk**: Low (may reject previously accepted formats — breaking change for liberal callers)

## Acceptance Criteria

- [ ] Only `YYYY-MM-DD` format accepted
- [ ] Other formats return 400 error
- [ ] Test covers rejection of ambiguous formats

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-14 | Created from code review | |

## Resources

- PR #24: https://github.com/joeasante/asthma-buddy/pull/24
