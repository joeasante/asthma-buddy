---
status: complete
priority: p2
issue_id: "332"
tags: [code-review, security, rate-limiting, notifications]
dependencies: []
---

# No Rate Limiting on Notification `mark_read` / `mark_all_read` Endpoints

## Problem Statement

`NotificationsController#mark_read` and `#mark_all_read` have no rate limiting. While these actions are authenticated (user can only affect their own notifications), an attacker who hijacks a session could flood these endpoints to exhaust database write capacity or generate noise in logs. More practically, a buggy frontend could repeatedly fire these requests. Other write endpoints in the app have rate limiting — notifications should follow the same pattern.

## Findings

**Flagged by:** security-sentinel (rated P2)

- `PATCH /notifications/:id/mark_read` — no rate limit
- `POST /notifications/mark_all_read` — no rate limit
- Other write endpoints use `rate_limit` (Rails 8 built-in)

## Proposed Solutions

### Option A: Add `rate_limit` to `NotificationsController` (Recommended)
```ruby
class NotificationsController < ApplicationController
  rate_limit to: 60, within: 1.minute, by: -> { Current.user.id }
  # ...
end
```

60 requests/minute is generous for genuine user interaction but blocks abusive patterns.

**Pros:** Consistent with rest of app; one line
**Cons:** None
**Effort:** Tiny
**Risk:** None

### Recommended Action

Option A.

## Technical Details

- **File:** `app/controllers/notifications_controller.rb`
- Rails 8 `rate_limit` is available: `rate_limit to: N, within: T`

## Acceptance Criteria

- [ ] `mark_read` and `mark_all_read` are rate-limited
- [ ] Rate limit response returns 429 on excess requests
- [ ] Normal usage (< 60/min) is unaffected

## Work Log

- 2026-03-12: Created from Milestone 2 code review — security-sentinel P2 finding
