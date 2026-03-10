---
status: pending
priority: p2
issue_id: "243"
tags: [code-review, security, rate-limiting, onboarding]
dependencies: []
---

# Missing Rate Limiting on Onboarding Write Actions

## Problem Statement

`submit_1` and `submit_2` create database records (`PersonalBestRecord` and `Medication`) with no rate limit. Every other write-path controller in the application applies `rate_limit` — sessions (10/3min), registrations (10/3min), profile updates (10/3min), account deletion (3/10min), symptom logs (10/1min), peak flow readings (10/1min). The onboarding controller is the only data-creation controller without rate limiting.

## Findings

- `onboarding_controller.rb` — no `rate_limit` declarations
- `submit_1` creates a `PersonalBestRecord` row on every valid submission — no ceiling per request window
- `submit_2` creates a `Medication` row on every valid submission
- Security reviewer: "Low severity — an authenticated user or compromised session could loop POST to create thousands of PersonalBestRecord rows"
- All comparable controllers confirmed to have `rate_limit` via security review

## Proposed Solutions

### Option 1: Add `rate_limit` consistent with other data-creation endpoints (Recommended)

**Approach:**

```ruby
class OnboardingController < ApplicationController
  layout "onboarding"
  rate_limit to: 10, within: 1.minute, only: %i[submit_1 submit_2]
  rate_limit to: 5,  within: 1.minute, only: :skip
  before_action :redirect_if_onboarding_complete
  # ...
end
```

Match the pattern used in `SymptomLogsController` and `PeakFlowReadingsController`.

**Pros:**
- Consistent with all other write controllers
- Prevents record flooding from a compromised session
- 3-line change

**Cons:**
- None meaningful

**Effort:** 10 minutes

**Risk:** Low

## Recommended Action

Option 1. Direct copy of the pattern from any other data controller.

## Technical Details

**Affected files:**
- `app/controllers/onboarding_controller.rb` — top of class, after `layout`

## Acceptance Criteria

- [ ] `rate_limit` declared for `submit_1` and `submit_2` (10/1min or similar)
- [ ] `rate_limit` declared for `skip` (5/1min or similar)
- [ ] Limits match the convention established by other data controllers
- [ ] `bin/rails test` passes

## Work Log

### 2026-03-10 — Code Review Discovery

**By:** Claude Code (ce:review)

**Actions:** Flagged by security reviewer. All other write controllers confirmed to have rate limiting.
