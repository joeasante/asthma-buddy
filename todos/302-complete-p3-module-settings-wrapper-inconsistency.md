---
status: pending
priority: p3
issue_id: "302"
tags: [code-review, rails, conventions, settings]
dependencies: []
---

# Settings::DoseLogsController and MedicationsController use module wrapper inconsistently

## Problem Statement
`app/controllers/settings/base_controller.rb` correctly uses `class Settings::BaseController`. However, `dose_logs_controller.rb` and `medications_controller.rb` use the older `module Settings; class DoseLogsController` wrapper style. The codebase should use a single consistent convention for namespaced controllers. The flat `class Settings::Foo` style is the Rails-preferred approach and matches the new base controller.

## Findings
**Flagged by:** kieran-rails-reviewer

**Files:**
- `app/controllers/settings/dose_logs_controller.rb` — uses `module Settings` wrapper
- `app/controllers/settings/medications_controller.rb` — uses `module Settings` wrapper
- `app/controllers/settings/base_controller.rb` — correctly uses `class Settings::BaseController`

## Proposed Solutions
### Option A — Update both controllers to flat style
```ruby
# Before:
module Settings
  class DoseLogsController < Settings::BaseController
    ...
  end
end

# After:
class Settings::DoseLogsController < Settings::BaseController
  ...
end
```
**Effort:** Trivial (cosmetic only, no functional change). **Risk:** None.

## Recommended Action

## Technical Details
- **Files:** `app/controllers/settings/dose_logs_controller.rb`, `app/controllers/settings/medications_controller.rb`

## Acceptance Criteria
- [ ] Both controllers use `class Settings::Foo` flat style
- [ ] `bin/rails test` passes after change

## Work Log
- 2026-03-12: Code review finding — kieran-rails-reviewer

## Resources
- Branch: dev
