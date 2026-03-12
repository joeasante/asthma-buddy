---
status: complete
priority: p2
issue_id: "327"
tags: [code-review, architecture, duplication, settings, dashboard]
dependencies: []
---

# `Settings::BaseController#set_dashboard_vars` Duplicates `DashboardController#index` Queries

## Problem Statement

`app/controllers/settings/base_controller.rb` contains a `set_dashboard_vars` method that runs on every settings page load. It duplicates — with an explicit warning comment — the same queries executed by `DashboardController#index`. Any time the dashboard query logic changes, it must be updated in two places. The comment acknowledges this sync risk, but the duplication remains unresolved. This is a maintainability debt that will cause divergence bugs.

## Findings

**Flagged by:** architecture-strategist (rated HIGH risk)

- `set_dashboard_vars` in `Settings::BaseController` runs identical or similar queries to `DashboardController#index`
- A comment in the code warns about the sync requirement
- Any query optimization or bug fix applied to the dashboard must also be applied here
- The settings pages don't appear to actually *need* all dashboard data — only specific stats for the settings header

## Proposed Solutions

### Option A: Extract a shared query object / service
Create a `DashboardStats` query object that both controllers call:

```ruby
# app/queries/dashboard_stats.rb
class DashboardStats
  def initialize(user) = @user = user
  def call = { peak_flow: ..., symptoms: ..., ... }
end
```

Both `DashboardController` and `Settings::BaseController` call `DashboardStats.new(Current.user).call`.

**Pros:** Single source of truth; DRY; easy to test
**Cons:** New abstraction to maintain
**Effort:** Medium
**Risk:** Low

### Option B: Audit what `set_dashboard_vars` actually uses in settings views
If settings pages only use 1-2 values from the "dashboard vars" set, eliminate `set_dashboard_vars` entirely and inline only what's needed.

**Pros:** Simplest — remove the duplication by removing the code
**Cons:** Requires auditing all settings views to understand actual usage
**Effort:** Small-Medium
**Risk:** Low

### Option C: Accept duplication, add a shared test
Keep both methods but add a shared test that asserts they produce equivalent output for the same user.

**Pros:** Minimal change; catches divergence
**Cons:** Doesn't fix the architectural problem
**Effort:** Small
**Risk:** Low (but leaves the debt)

### Recommended Action

Option B first — audit what settings views actually use. If it's minimal, delete `set_dashboard_vars` and inline. If the full dashboard dataset is genuinely needed, then Option A.

## Technical Details

- **File:** `app/controllers/settings/base_controller.rb:13-39` (approx)
- Related: `app/controllers/dashboard_controller.rb`

## Acceptance Criteria

- [ ] `set_dashboard_vars` either removed or replaced with shared query object
- [ ] No duplicate query logic between settings and dashboard controllers
- [ ] All settings pages still render correctly with correct data

## Work Log

- 2026-03-12: Created from Milestone 2 code review — architecture-strategist HIGH finding
