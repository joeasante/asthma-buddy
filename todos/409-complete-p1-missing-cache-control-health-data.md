---
status: complete
priority: p1
issue_id: "409"
tags: [code-review, security, gdpr, api, caching]
dependencies: []
---

# Missing Cache-Control Headers on API Health Data Responses

## Problem Statement

API responses containing sensitive health data (symptom logs, peak flow readings, medications, dose logs) have no `Cache-Control: no-store` header. `ActionController::API` does not set this by default. Intermediate proxies or browser HTTP caches could store medical data. Under UK GDPR Article 9, health data is "special category" data requiring enhanced protection.

## Findings

**Flagged by:** security-sentinel

**Location:** `app/controllers/api/v1/base_controller.rb` — no cache headers set

## Proposed Solutions

### Option A: Add before_action to BaseController (Recommended)

```ruby
before_action :set_cache_headers

def set_cache_headers
  response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, private"
  response.headers["Pragma"] = "no-cache"
end
```

- **Pros:** One-line fix, covers all API endpoints, GDPR compliant
- **Cons:** None
- **Effort:** Small (2 min)
- **Risk:** None

## Acceptance Criteria

- [ ] All API responses include `Cache-Control: no-store` header
- [ ] Test verifies header presence

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-14 | Created from Phase 28 code review | GDPR requirement for health data |
