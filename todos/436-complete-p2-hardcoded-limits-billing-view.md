---
status: pending
priority: p2
issue_id: 436
tags: [code-review, quality, billing]
dependencies: []
---

# Billing View Hardcodes Plan Limits Instead of Reading from PLANS Constant

## Problem Statement

The billing show view hardcodes "30 days symptom log history" and "30 days peak flow history" as text. If `PLANS[:free][:features][:symptom_log_history_days]` changes to 14, the view will still say 30.

## Findings

- **Source:** Rails Reviewer
- **Location:** `app/views/settings/billing/show.html.erb`

## Proposed Solutions

Render from the PLANS constant:

```erb
<li><%= PLANS[:free][:features][:symptom_log_history_days] %> days symptom log history</li>
```

- **Effort:** Small (5 minutes)
- **Risk:** None

## Acceptance Criteria

- [ ] Billing view reads limits from PLANS constant
- [ ] Changing PLANS values automatically updates the view

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-15 | Created from Phase 29 code review | |
