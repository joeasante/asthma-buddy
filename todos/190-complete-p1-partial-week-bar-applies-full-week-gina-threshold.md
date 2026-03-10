---
status: complete
priority: p1
issue_id: "190"
tags: [code-review, clinical, architecture, phase-15-1]
dependencies: []
---

# Partial-Week First Bar Applies Full-Week GINA Threshold — Clinical Misclassification

## Problem Statement
`build_weekly_data` uses `period_start` (e.g. a Thursday 8 weeks ago) as `week_start` for the first iteration. The first bar therefore covers only the remaining days of that partial week (e.g. Thursday–Sunday = 4 days). However, the GINA band threshold (`gina_band`) applies the same threshold as a full week: 3+ uses = `:review`. On a partial 4-day window, 3 uses is proportionally equivalent to 5+ uses per week — the bar will be classified as "review" when a full-week calculation would show "controlled". This is a clinical misclassification that could mislead users into thinking their asthma is less well-controlled than it is.

## Findings
- **File:** `app/controllers/reliever_usage_controller.rb:57-83`
- `week_start = current` on first iteration means first bar spans `period_start..week_sunday` (1–6 days)
- All subsequent bars span exactly 7 days (Monday–Sunday)
- `gina_band` applies identical threshold regardless of window duration
- Architecture agent rated this P1 due to clinical impact
- A user with 3 reliever uses in a partial 4-day window would see a yellow "Review" bar — inflating the apparent severity

## Proposed Solutions

### Option A (Recommended): Always start bars on Monday boundaries
Set `week_start = week_monday` (not `current`) on the first iteration. Accept that the earliest bar may include 1–3 days before the strict `@weeks.weeks.ago` boundary. This is standard practice for weekly charts and makes all bars represent equal 7-day windows with consistent thresholds.

```ruby
week_start = week_monday  # was: current
week_end   = [week_sunday, Date.current].min
```
- Effort: Small (1 line change in `build_weekly_data`)
- Risk: Low — slightly expands the first bar's date range by 0-6 days

### Option B: Prorate threshold for partial windows
Scale the threshold by `(week_end - week_start + 1) / 7.0`. For a 4-day window, the `:review` threshold becomes `3 * (4/7.0).ceil = 2` uses. More clinically accurate but more complex to explain to users.
- Effort: Medium
- Risk: Medium — complicates the classification logic and the GINA legend

### Option C: Show partial week as greyed out / labelled differently
Add a `partial: true` flag to the first week hash and render it with reduced opacity or a "partial week" tooltip in the view.
- Effort: Medium
- Risk: Low

## Recommended Action

## Technical Details
- Affected files: `app/controllers/reliever_usage_controller.rb:57-83`
- GINA thresholds: 0-2 = controlled, 3-5 = review, 6+ = urgent

## Acceptance Criteria
- [ ] All rendered bars represent equal-duration (7-day) windows OR partial weeks are clearly labelled
- [ ] GINA band classification is not applied to partial-week data without adjustment
- [ ] Unit test verifying that a period starting on a non-Monday produces correctly-bounded bars

## Work Log
- 2026-03-10: Identified by architecture-strategist as P1 clinical issue in Phase 15.1 review
