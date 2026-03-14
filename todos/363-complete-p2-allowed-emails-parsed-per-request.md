---
status: complete
priority: p2
issue_id: 363
tags: [code-review, architecture]
dependencies: []
---

## Problem Statement

`@allowed_emails` is memoized per-request (new controller instance each request). The ENV parse is cheap but misleading — it looks like a cache but isn't. Could be parsed at boot time.

## Findings

In `app/controllers/application_controller.rb`, the `@allowed_emails` instance variable is set by parsing `ENV["ALLOWED_EMAILS"]` (splitting by comma, stripping whitespace, downcasing). Since a new controller instance is created for each request, this memoization only persists within a single request — the `||=` pattern gives the false appearance of caching across requests. While the performance impact is negligible, the code is misleading and the parsed result is unavailable outside controllers.

## Proposed Solutions

**A) Parse at boot time in an initializer: `Rails.application.config.allowed_emails = ENV["ALLOWED_EMAILS"]&.split(",")&.map(&:strip)&.map(&:downcase)`**
- Pros: Parsed once; available anywhere via `Rails.application.config`; clear semantics
- Cons: Requires app restart to pick up ENV changes (standard for ENV-based config)

**B) Use a class-level memoization with `@@` or `class_attribute`**
- Pros: Parsed once per class load; stays in the controller layer
- Cons: Class variables have thread-safety nuances; `class_attribute` is better but still controller-scoped

**C) Leave as-is (performance impact is negligible)**
- Pros: No change required
- Cons: Misleading memoization pattern; value unavailable outside controllers

## Recommended Action



## Technical Details

**Affected files:**
- `app/controllers/application_controller.rb`

## Acceptance Criteria

- [ ] ALLOWED_EMAILS parsed once at boot, not per-request
- [ ] Available outside controllers if needed
