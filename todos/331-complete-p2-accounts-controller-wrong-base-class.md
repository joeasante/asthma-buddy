---
status: complete
priority: p2
issue_id: "331"
tags: [code-review, architecture, settings, authorization]
dependencies: []
---

# `Settings::AccountsController` Inherits `ApplicationController` Instead of `Settings::BaseController`

## Problem Statement

`app/controllers/settings/accounts_controller.rb` inherits from `ApplicationController` directly instead of `Settings::BaseController`. All other controllers in `app/controllers/settings/` inherit from `Settings::BaseController`, which provides authentication enforcement, header eyebrow variable setup, and any settings-specific before_actions. `AccountsController` bypasses these by inheriting from `ApplicationController`, which means it may be missing settings-specific guards and layout/variable setup.

## Findings

**Flagged by:** architecture-strategist (rated MODERATE)

```ruby
# app/controllers/settings/accounts_controller.rb:4
class Settings::AccountsController < ApplicationController  # BUG: should be Settings::BaseController
```

Expected:
```ruby
class Settings::AccountsController < Settings::BaseController
```

## Proposed Solutions

### Option A: Change base class to `Settings::BaseController` (Recommended)
One-line fix.

**Pros:** Consistent with all other settings controllers; inherits correct before_actions
**Cons:** May require removing any duplicate `authenticate_user!` calls now handled by base
**Effort:** Tiny
**Risk:** Low — test after to ensure account deletion still works correctly

### Recommended Action

Option A.

## Technical Details

- **File:** `app/controllers/settings/accounts_controller.rb`
- `Settings::BaseController`: `app/controllers/settings/base_controller.rb`

## Acceptance Criteria

- [ ] `AccountsController` inherits from `Settings::BaseController`
- [ ] Account deletion still works (redirects to root, clears session)
- [ ] No duplicate authentication enforcement
- [ ] Existing account controller tests pass

## Work Log

- 2026-03-12: Created from Milestone 2 code review — architecture-strategist MODERATE finding
