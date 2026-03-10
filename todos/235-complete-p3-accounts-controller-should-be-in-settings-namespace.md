---
status: pending
priority: p3
issue_id: "235"
tags: [code-review, architecture, rails]
dependencies: []
---

# AccountsController at top-level namespace — inconsistent with Settings module pattern

## Problem Statement

The app namespaces settings-tier controllers under the `Settings` module (`app/controllers/settings/`, routed under `/settings`). Account deletion is a settings-tier action (accessed from `settings/show`, redirects to `settings_path` on failure). `AccountsController` is at the top-level namespace, making it a peer of `SymptomLogsController` and `PeakFlowReadingsController` (primary domain controllers), which is architecturally misleading.

## Findings

**Flagged by:** phase-16-code-reviewer

**Location:** `app/controllers/accounts_controller.rb`, `config/routes.rb`, `app/views/settings/show.html.erb`

## Proposed Solutions

### Option A (Recommended) — Move into Settings namespace

Rename to `Settings::AccountController` at `app/controllers/settings/account_controller.rb`. Move the route inside the `scope "/settings", module: :settings` block. Path becomes `DELETE /settings/account`, helper becomes `settings_account_path`.

**Steps:**
1. Create `app/controllers/settings/account_controller.rb`:
   ```ruby
   class Settings::AccountController < ApplicationController
     # ... move destroy action here
   end
   ```
2. Delete `app/controllers/accounts_controller.rb`
3. Update `config/routes.rb`:
   ```ruby
   scope "/settings", module: :settings do
     resource :account, only: [:destroy]
     # ... existing settings routes
   end
   ```
4. Update `app/views/settings/show.html.erb` form url from `account_path` to `settings_account_path`
5. Update any references in tests

**Effort:** Low
**Risk:** Low — one controller, one route, one view reference

### Option B — Keep current placement, document the exception

Add a comment to `AccountsController` explaining why it lives at the top level despite being a settings action.

**Effort:** Trivial
**Risk:** None — technical debt preserved

## Recommended Action

Option A. The architectural consistency is worth the small refactor. The `Settings` namespace exists precisely for this kind of controller.

## Technical Details

**Acceptance Criteria:**
- [ ] `AccountsController` is nested under `Settings` module
- [ ] Route is `/settings/account` (DELETE)
- [ ] All tests pass with updated path helpers

## Work Log

- 2026-03-10: Identified by phase-16-code-reviewer.
