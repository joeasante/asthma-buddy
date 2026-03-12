---
status: pending
priority: p1
issue_id: 306
tags: [code-review, rails]
---

# 306 — P1 — ErrorsController inherits ApplicationController (secondary exception risk during DB outage)

## Problem Statement

`ErrorsController < ApplicationController` pulls in the `set_notification_badge_count` before_action inherited from `ApplicationController`. That before_action calls `Current.user.notifications.unread.count` — a live database query — before the error view renders.

If the original 500 was caused by a database failure, this inherited before_action will raise a secondary exception. Rails will attempt to fall back to `public/500.html`, which does not exist in this project, resulting in a bare Rails error page being served to the user instead of the styled 500 view.

## Findings

- `ErrorsController < ApplicationController` — inherits all before_actions including `set_notification_badge_count`
- `set_notification_badge_count` performs `Current.user.notifications.unread.count` (DB query)
- No `skip_before_action` is present in `ErrorsController`
- `public/500.html` does not exist — the Rails fallback page will be shown on a secondary exception
- The 404 error action is lower-risk (not triggered by DB failures) but is equally affected

**Affected file:** `app/controllers/errors_controller.rb`

## Proposed Solutions

### Option A — Skip the before_action (recommended)
Add a single line to `ErrorsController`:

```ruby
skip_before_action :set_notification_badge_count
```

This is the minimal, targeted fix. The errors controller does not need the notification badge count — error pages do not render the application nav in the same way as normal pages.

### Option B — Inherit from ActionController::Base
Change `ErrorsController < ApplicationController` to `ErrorsController < ActionController::Base`. This guarantees no ApplicationController callbacks can leak in, at the cost of losing any other helpers (e.g. `authenticated?`, `Current` setup) that may be genuinely needed by the error views.

### Option C — Rescue the before_action
Wrap `set_notification_badge_count` in a rescue block so secondary exceptions are swallowed. This is the least preferred option — it hides the symptom rather than treating the root cause, and leaves the DB query in the hot path for every error page render.

## Acceptance Criteria

- [ ] `ErrorsController` does not invoke `set_notification_badge_count` (verified via `skip_before_action` or base class change)
- [ ] Rendering `errors#internal_server_error` does not raise when the database is unavailable
- [ ] A unit test or integration test exercises the 500 route and asserts it renders without error when DB queries fail (can use a stub/mock)
- [ ] `public/500.html` existence is confirmed or the fallback path is otherwise handled (tracked separately or addressed as part of this ticket)

## Technical Details

| Field | Value |
|---|---|
| Affected file | `app/controllers/errors_controller.rb` |
| Root cause | Inherited `set_notification_badge_count` before_action performs a DB query on every error page render |
| Failure mode | Secondary exception during DB outage → Rails falls back to `public/500.html` → file missing → bare Rails error page |
| Severity | P1 — reproducible in production under DB outage |
| Related issue | Todo 308 addresses a second DB query risk on the 500 view itself |
