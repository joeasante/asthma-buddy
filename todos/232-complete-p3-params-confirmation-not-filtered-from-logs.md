---
status: pending
priority: p3
issue_id: "232"
tags: [code-review, security, logging]
dependencies: []
---

# `params[:confirmation]` value "DELETE" logged in plaintext in request logs

## Problem Statement

`config/initializers/filter_parameter_logging.rb` filters health data and auth params but not `:confirmation`. Every successful account deletion logs `Parameters: {"confirmation"=>"DELETE", ...}` in plaintext. The string itself is not sensitive, but the log entry confirms a deletion event. The `authenticity_token` parameter is also logged, which is unnecessary noise (though not reusable, it's CSRF token data). Both are low-severity but inconsistent with the comprehensive log filtering already in place.

## Findings

**Flagged by:** phase-16-code-reviewer

**Location:** `config/initializers/filter_parameter_logging.rb`

## Proposed Solutions

### Option A (Recommended) — Add both params to the filter list

Add `:confirmation` and `:authenticity_token` to `Rails.application.config.filter_parameters`:

```ruby
Rails.application.config.filter_parameters += [
  :passw, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn,
  :confirmation, :authenticity_token
]
```

**Effort:** Trivial — two entries added to existing list
**Risk:** None — filtered params still appear in logs as `[FILTERED]`, no runtime behaviour changes

## Recommended Action

Option A. Both params are appropriate to filter: `confirmation` reveals a deletion event, and `authenticity_token` is CSRF material that has no log analysis value.

## Technical Details

**Acceptance Criteria:**
- [ ] `confirmation` param filtered from logs (appears as `[FILTERED]`)
- [ ] `authenticity_token` filtered from logs

## Work Log

- 2026-03-10: Identified by phase-16-code-reviewer.
