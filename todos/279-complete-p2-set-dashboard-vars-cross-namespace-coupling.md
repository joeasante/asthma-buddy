---
status: pending
priority: p2
issue_id: "279"
tags: [code-review, rails, architecture, turbo-streams, dashboard, settings]
dependencies: ["275"]
---

# `set_dashboard_vars` in `Settings::DoseLogsController` — cross-namespace coupling

## Problem Statement

`Settings::DoseLogsController#create` calls `set_dashboard_vars`, which rebuilds three dashboard queries (`@preventer_adherence`, `@reliever_medications`, `@active_illness`) and renders these into a Turbo Stream that replaces `"today-doses-list"` on the dashboard.

This coupling is intentional (dose logging from the dashboard quick-log UI should update the dashboard in real-time) but architecturally problematic: a controller in the `settings/` namespace owns the computation of dashboard state. If `DashboardController#index` ever changes how these three variables are assembled, `DoseLogsController` will break silently at runtime with stale data or a broken partial, not at compile time.

The maintenance trap: a developer modifying dashboard queries must audit both controllers. Nothing in `DashboardController` points to the fact that a settings controller shadows its logic.

## Findings

- **File:** `app/controllers/settings/dose_logs_controller.rb:49–69` — `set_dashboard_vars`
- **File:** `app/views/settings/dose_logs/create.turbo_stream.erb:11–17` — renders `dashboard/today_doses_list`
- **Agents:** architecture-strategist, code-simplicity-reviewer
- Note: This is NOT dead code — dose logging from the dashboard's quick-log UI does reach `DoseLogsController#create` and the `today-doses-list` target IS in the DOM at that moment

## Proposed Solutions

### Option A — Extract to a shared query object / concern (Recommended)

Create a `DashboardQueries` concern or query object:

```ruby
# app/models/concerns/dashboard_queries.rb (or a simple plain object)
module DashboardQueries
  def self.today_doses_slice(user)
    {
      preventer_adherence: ...,
      reliever_medications: ...,
      active_illness: ...
    }
  end
end
```

Both `DashboardController` and `DoseLogsController` call this by name. The query logic lives in one place.

**Pros:** Single source of truth. Breaking changes in query shape become compile-time errors.
**Cons:** Slightly more indirection.
**Effort:** Small–Medium
**Risk:** Low

### Option B — Leave as-is with a prominent code comment

Add a `# NOTE: this mirrors DashboardController — keep in sync` comment and accept the coupling as a pragmatic trade-off for a solo developer.

**Pros:** Fastest.
**Cons:** The next developer (or future you) will hit this eventually.
**Effort:** Trivial
**Risk:** Medium (silent drift over time)

### Option C — Keep `set_dashboard_vars` but consolidate under `Settings::BaseController`

Move `set_dashboard_vars` to `Settings::BaseController` (from todo 275). Makes the coupling at least visible and shared, even if not eliminated.

**Pros:** Pairs well with 275. Reduces duplication.
**Cons:** Still couples settings to dashboard.
**Effort:** Small
**Risk:** Low

## Recommended Action

Option C as an immediate improvement (pairs with 275). Option A as a follow-on if the app grows.

## Technical Details

- **Affected files:**
  - `app/controllers/settings/dose_logs_controller.rb`
  - `app/controllers/settings/base_controller.rb` (from todo 275)

## Acceptance Criteria

- [ ] `set_dashboard_vars` is not duplicated if additional Settings controllers need it
- [ ] Behaviour unchanged: logging a dose from the dashboard updates `today-doses-list`
- [ ] Code comment explains the cross-namespace intent

## Work Log

- 2026-03-11: Identified by architecture-strategist and code-simplicity-reviewer during code review of dev branch
