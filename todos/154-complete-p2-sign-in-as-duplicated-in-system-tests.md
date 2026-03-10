---
status: pending
priority: p2
issue_id: "154"
tags: [code-review, testing, duplication, system-tests]
dependencies: []
---

# `sign_in_as` Helper Duplicated Across 8 System Test Files

## Problem Statement

`ApplicationSystemTestCase` does not define a `sign_in_as` helper. Every system test file defines an identical copy of the method. A future change to the sign-in flow (button text, redirect URL, password default) requires updating 8 files.

## Findings

**Flagged by:** pattern-recognition-specialist (P2)

**Files with identical `sign_in_as` definition (8 total):**
- `test/system/medical_history_test.rb`
- `test/system/dose_logging_test.rb`
- `test/system/peak_flow_display_test.rb`
- `test/system/peak_flow_recording_test.rb`
- `test/system/adherence_test.rb`
- `test/system/medication_management_test.rb`
- `test/system/symptom_logging_test.rb`
- `test/system/low_stock_test.rb`

**Duplicated method (identical in all 8 files):**
```ruby
def sign_in_as(user, password: "password123")
  visit new_session_url
  fill_in "Email address", with: user.email_address
  fill_in "Password", with: password
  click_button "Sign in"
  assert_current_path dashboard_url
end
```

**`ApplicationSystemTestCase` current state** (`test/application_system_test_case.rb`):
```ruby
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]
end
```

## Proposed Solutions

### Option A — Move to `ApplicationSystemTestCase` (Recommended)

```ruby
# test/application_system_test_case.rb
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  def sign_in_as(user, password: "password123")
    visit new_session_url
    fill_in "Email address", with: user.email_address
    fill_in "Password", with: password
    click_button "Sign in"
    assert_current_path dashboard_url
  end
end
```

Then remove the local `def sign_in_as` definition from all 8 test files.

**Pros:** Single definition. Future changes are a 1-file edit.
**Effort:** Small (add once, remove 8 copies)
**Risk:** None — all tests still inherit the same method

## Acceptance Criteria

- [ ] `ApplicationSystemTestCase` defines `sign_in_as`
- [ ] Zero local `def sign_in_as` definitions in any `test/system/*.rb` file
- [ ] `bin/rails test:system` passes all system tests

## Work Log

- 2026-03-09: Identified by pattern-recognition-specialist during `ce:review`. Phase 15 introduced the 8th duplicate — good time to consolidate.
