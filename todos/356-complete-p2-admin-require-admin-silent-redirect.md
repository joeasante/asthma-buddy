---
status: complete
priority: p2
issue_id: 356
tags: [code-review, security, admin]
dependencies: []
---

## Problem Statement

`Admin::BaseController#require_admin` does `redirect_to root_path` with no flash message, no JSON error for API clients, and no logging of unauthorized access attempts. Health app admin access attempts should be logged.

## Findings

In `app/controllers/admin/base_controller.rb`, the `require_admin` method silently redirects non-admin users to the root path. There is no flash message informing the user why they were redirected, no `respond_to` block to return a 403 JSON error for API clients, and no audit logging of the unauthorized access attempt. For a health application, failed admin access attempts are security-relevant events that should be tracked.

## Proposed Solutions

**A) Add audit logging, flash message, and respond_to with JSON 403 (Comprehensive)**
- Pros: Full visibility into unauthorized access attempts; good UX with flash message; supports JSON API clients
- Cons: More code to add

**B) Just add flash message and logging (Minimal)**
- Pros: Quick to implement; addresses the most critical gaps
- Cons: Still no JSON support for API clients

## Recommended Action



## Technical Details

**Affected files:**
- `app/controllers/admin/base_controller.rb`

## Acceptance Criteria

- [ ] Non-admin access attempts are logged with user ID and path
- [ ] JSON clients get 403 with error message
- [ ] HTML clients get a flash alert
