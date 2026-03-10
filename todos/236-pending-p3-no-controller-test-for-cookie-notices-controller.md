---
status: pending
priority: p3
issue_id: "236"
tags: [code-review, testing, rails]
dependencies: []
---

# CookieNoticesController has no controller test — covered only by slower system test

## Problem Statement

The cookie notice dismiss behaviour is covered by a Capybara system test only. A fast integration test asserting `POST /cookie-notice/dismiss` returns 204 and sets `session[:cookie_notice_shown]` would be more reliable and run in milliseconds vs seconds.

## Findings

**Flagged by:** phase-16-code-reviewer

**Location:** New file: `test/controllers/cookie_notices_controller_test.rb`

## Proposed Solutions

### Option A (Recommended) — Add a dedicated controller test

Create `test/controllers/cookie_notices_controller_test.rb` covering:

1. `POST /cookie-notice/dismiss` returns 204 and sets the session flag
2. The endpoint is accessible without authentication
3. A subsequent page render does not include the cookie notice partial

```ruby
require "test_helper"

class CookieNoticesControllerTest < ActionDispatch::IntegrationTest
  test "POST dismiss returns 204" do
    post cookie_notice_dismiss_path
    assert_response :no_content
  end

  test "POST dismiss sets session flag" do
    post cookie_notice_dismiss_path
    assert session[:cookie_notice_shown]
  end

  test "POST dismiss accessible without authentication" do
    # No sign_in — request must succeed
    post cookie_notice_dismiss_path
    assert_response :no_content
  end

  test "cookie notice not rendered after dismiss" do
    post cookie_notice_dismiss_path
    get root_path  # or any HTML page
    assert_select "[data-cookie-notice]", count: 0
  end
end
```

**Effort:** Low — new test file, ~20 lines
**Risk:** None

## Recommended Action

Add the controller test. System tests are slow and fragile for verifying a single HTTP interaction and session assignment. Controller tests are the right tool here.

## Technical Details

**Acceptance Criteria:**
- [ ] Controller test file created
- [ ] Test asserts 204 response
- [ ] Test asserts `session[:cookie_notice_shown]` is truthy after POST
- [ ] Test asserts endpoint accessible without authentication

## Work Log

- 2026-03-10: Identified by phase-16-code-reviewer.
