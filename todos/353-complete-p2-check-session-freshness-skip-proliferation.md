---
status: complete
priority: p2
issue_id: 353
tags: [code-review, architecture, maintenance]
dependencies: []
---

## Problem Statement

The session timeout `before_action :check_session_freshness` is global in ApplicationController, requiring `skip_before_action` in 8 controllers. Every future unauthenticated controller must remember to add this skip, creating a maintenance burden and a source of bugs.

## Findings

`check_session_freshness` is defined as a global `before_action` in `app/controllers/application_controller.rb`. The following 8 controllers each have `skip_before_action :check_session_freshness`:

- `app/controllers/sessions_controller.rb`
- `app/controllers/registrations_controller.rb`
- `app/controllers/passwords_controller.rb`
- `app/controllers/home_controller.rb`
- `app/controllers/pages_controller.rb`
- `app/controllers/errors_controller.rb`
- `app/controllers/cookie_notices_controller.rb`
- `app/controllers/email_verifications_controller.rb`
- `test/controllers/test/sessions_controller.rb` (test helper)

The pattern `if: :authenticated?` is already used by `set_notification_badge_count` in the same file, so this would be consistent with existing conventions.

## Proposed Solutions

**A) Change to `before_action :check_session_freshness, if: :authenticated?` and remove all skip lines (Recommended)**
- Pros: 1 line changed, 8 lines removed; eliminates an entire class of future bugs; follows existing pattern
- Cons: None significant

**B) Move the `authenticated?` check inside the method body**
- Pros: Works without changing the before_action declaration
- Cons: Less idiomatic Rails; method still runs on every request even if short-circuited

## Recommended Action



## Technical Details

**Affected files:**
- `app/controllers/application_controller.rb`
- `app/controllers/sessions_controller.rb`
- `app/controllers/registrations_controller.rb`
- `app/controllers/passwords_controller.rb`
- `app/controllers/home_controller.rb`
- `app/controllers/pages_controller.rb`
- `app/controllers/errors_controller.rb`
- `app/controllers/cookie_notices_controller.rb`
- `app/controllers/email_verifications_controller.rb`
- `test/controllers/test/sessions_controller.rb`

## Acceptance Criteria

- [ ] No `skip_before_action :check_session_freshness` exists in any controller
- [ ] Session timeout still works for authenticated users
- [ ] Unauthenticated pages work without errors
