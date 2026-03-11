---
status: pending
priority: p3
issue_id: "263"
tags: [code-review, rails, cleanup]
dependencies: []
---

# Redundant `before_action :require_authentication` in NotificationsController

## Problem Statement

`NotificationsController` explicitly declares `before_action :require_authentication` on line 4. This is unnecessary: `ApplicationController` includes the `Authentication` concern which registers `before_action :require_authentication` for the entire application. Every other controller in the project relies on the inherited callback and only uses `allow_unauthenticated_access` to opt out. The duplicate declaration is a no-op but misleads readers into thinking controllers must re-declare this protection themselves.

## Findings

`app/controllers/notifications_controller.rb` line 4:

```ruby
class NotificationsController < ApplicationController
  before_action :require_authentication  # redundant — inherited from ApplicationController
  before_action :set_notification, only: %i[mark_read]
  # ...
end
```

No other feature controller in the project (e.g. `DoseLogsController`, `Settings::MedicationsController`, `HealthEventsController`) repeats this declaration. They all rely on inheritance alone.

Confirmed by: kieran-rails-reviewer.

## Proposed Solutions

### Option A — Remove the redundant declaration *(Recommended)*

```ruby
class NotificationsController < ApplicationController
  before_action :set_notification, only: %i[mark_read]
  # ...
end
```

Pros: consistent with every other controller in the project; removes the misleading signal
Cons: none — behaviour is identical

## Recommended Action

Option A — delete the `before_action :require_authentication` line from `NotificationsController`.

## Technical Details

- **Affected file:** `app/controllers/notifications_controller.rb` line 4

## Acceptance Criteria

- [ ] `before_action :require_authentication` is not present in `NotificationsController`
- [ ] All notification endpoints remain protected (unauthenticated requests are redirected / rejected)
- [ ] Existing controller tests for notifications continue to pass

## Work Log

- 2026-03-11: Found by kieran-rails-reviewer during Phase 19 code review
