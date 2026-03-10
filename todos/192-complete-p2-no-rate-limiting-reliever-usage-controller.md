---
status: complete
priority: p2
issue_id: "192"
tags: [code-review, security, rate-limiting, phase-15-1]
dependencies: []
---

# No Rate Limiting on `RelieverUsageController#index`

## Problem Statement
Every other authenticated read-heavy endpoint in the codebase uses Rails 8's `rate_limit`. `RelieverUsageController#index` executes up to 4 separate SQL queries per request (medications, dose_logs, peak_flow_readings, monthly stats). An authenticated user with a valid session can flood this endpoint with no throttle, creating CPU and SQLite I/O amplification. This is consistent with the project's existing pattern of adding rate limiting to controllers that perform non-trivial query work.

## Findings
- **File:** `app/controllers/reliever_usage_controller.rb:3`
- Executes 3–4 queries per request
- No `rate_limit` declaration
- Pre-existing gap documented in todo 068 (write endpoints); this is a read endpoint with similar query load
- Security agent rated this P2

## Proposed Solutions

### Option A (Recommended): Add `rate_limit` matching sibling controllers
```ruby
class RelieverUsageController < ApplicationController
  rate_limit to: 60, within: 1.minute, with: -> {
    respond_to do |format|
      format.html { render plain: "Too many requests", status: :too_many_requests }
      format.json { render json: { error: "Too many requests" }, status: :too_many_requests }
    end
  }
end
```
- Effort: Small
- Risk: None

## Recommended Action

## Technical Details
- Affected files: `app/controllers/reliever_usage_controller.rb`

## Acceptance Criteria
- [ ] `rate_limit` added with appropriate threshold (60/min)
- [ ] Both `format.html` and `format.json` handlers in the rate limit block
- [ ] Test for 429 response on exceeded rate limit

## Work Log
- 2026-03-10: Identified by security-sentinel in Phase 15.1 review
