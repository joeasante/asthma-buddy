---
status: complete
priority: p2
issue_id: "196"
tags: [code-review, turbo, frontend, phase-15-1]
dependencies: []
---

# Monthly Eyebrow Stat Outside Turbo Frame — Stale on Period Toggle + Wasted Queries

## Problem Statement
`@monthly_uses` and the eyebrow pill (`@monthly_pill_class`/`@monthly_pill_label`) are rendered in `page-header` outside `<turbo-frame id="reliever-frame">`. When the user clicks "8 weeks" or "12 weeks", Turbo replaces only the frame content. The eyebrow is intentionally static (it's always current-month), but `setup_monthly_stats` still fires the monthly stats DB query on every Turbo Frame request — the result is computed but its HTML is immediately discarded by Turbo.

This is the pattern documented in todo 171 (`header-queries-fire-on-turbo-frame-requests`).

## Findings
- **File:** `app/views/reliever_usage/index.html.erb:3-27` (outside frame); `app/controllers/reliever_usage_controller.rb:42` (`setup_monthly_stats` called unconditionally)
- `setup_monthly_stats` fires on every request including turbo_frame period toggles
- The monthly stat HTML (eyebrow pill) is outside the frame and thus discarded on frame requests
- Learnings researcher surfaced todo 171 as directly applicable

## Proposed Solutions

### Option A (Recommended): Guard with `turbo_frame_request?`
```ruby
def index
  # ... existing setup ...

  unless turbo_frame_request?
    setup_monthly_stats
  end
end
```
Set defaults for the ivars so the view doesn't error on frame requests where the eyebrow is discarded anyway:
```ruby
# at top of action:
@monthly_uses = 0
@monthly_pill_class = "eyebrow-pill--green"
@monthly_pill_label = "Well controlled"
```
- Effort: Small
- Risk: Low — the eyebrow is not inside the frame so the user never sees stale data

### Option B: Move eyebrow inside the Turbo Frame
Move the `page-header-eyebrow` div inside `<turbo-frame id="reliever-frame">` so it refreshes with the period toggle. This is semantically correct if the eyebrow should always reflect the current-month (not the selected period) — but then it doesn't actually need to be inside the frame at all.
- Effort: Medium (requires layout restructure)
- Risk: Low

## Recommended Action

## Technical Details
- Affected files: `app/controllers/reliever_usage_controller.rb`, `app/views/reliever_usage/index.html.erb`
- Related: todo 171 (header-queries-fire-on-turbo-frame-requests — complete)

## Acceptance Criteria
- [ ] `setup_monthly_stats` is not called (or is no-op) on turbo_frame requests
- [ ] No wasted DB query on period toggle clicks
- [ ] Eyebrow pill continues to show correct current-month data on full page loads

## Work Log
- 2026-03-10: Identified by kieran-rails-reviewer and learnings-researcher in Phase 15.1 review
