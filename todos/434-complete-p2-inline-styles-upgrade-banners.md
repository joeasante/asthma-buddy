---
status: pending
priority: p2
issue_id: 434
tags: [code-review, quality, design-system, billing]
dependencies: []
---

# Extract Inline Styles and Duplicated Upgrade Banner

## Problem Statement

The upgrade banners in `symptom_logs/index.html.erb` and `peak_flow_readings/index.html.erb` use identical inline styles (`style="border-left: 3px solid var(--brand); margin-bottom: 1.5rem;"`) and duplicated markup. This violates the design system conventions and DRY principle.

## Findings

- **Source:** Pattern Recognition, Rails Reviewer, Architecture Strategist, Simplicity Reviewer
- **Location:** `app/views/symptom_logs/index.html.erb` and `app/views/peak_flow_readings/index.html.erb`

## Proposed Solutions

1. Create `.section-card--upsell` CSS class
2. Extract `app/views/shared/_upgrade_banner.html.erb` partial
3. Render in both views with appropriate upgrade text

- **Effort:** Small (15 minutes)
- **Risk:** None

## Acceptance Criteria

- [ ] No inline styles on upgrade banners
- [ ] Shared partial used in both views
- [ ] Visual appearance unchanged

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-15 | Created from Phase 29 code review | Flagged by 4 agents |
