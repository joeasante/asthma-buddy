---
status: pending
priority: p2
issue_id: "132"
tags: [code-review, security, api, agent-native, settings]
dependencies: []
---

# 308 Permanent Redirect on POST Silently Drops Request Body

## Problem Statement

`SettingsController#update_personal_best` responds with `status: :permanent_redirect` (308). While 308 is RFC-correct for preserving method and body, many HTTP client libraries (Ruby `Net::HTTP`, Python `requests`, JavaScript `fetch`) do NOT forward the body on 308 by default. An agent posting to the legacy `POST /settings/personal_best` URL loses its params silently, gets a 422 from the target endpoint, and has no indication that its data was discarded.

Flagged by: security-sentinel (F-02), agent-native-reviewer (critical).

## Findings

**File:** `app/controllers/settings_controller.rb`

```ruby
def update_personal_best
  redirect_to profile_personal_best_path, status: :permanent_redirect, allow_other_host: false
end
```

A 308 on POST caches the redirect permanently in browsers, and most non-browser clients silently drop the body. This is a data-loss risk for agents using the old URL.

**Additional concern:** 308 is permanent — browsers and caches will replay the redirect indefinitely. If the profile path changes, there is no way to update clients that have cached the 308.

## Proposed Solutions

**Solution A — Return 410 Gone for JSON clients (recommended short-term):**
```ruby
def update_personal_best
  respond_to do |format|
    format.html { redirect_to profile_personal_best_path, status: :permanent_redirect }
    format.json do
      render json: {
        error: "This endpoint has moved.",
        new_url: profile_personal_best_url
      }, status: :gone
    end
  end
end
```
Agents receive an actionable 410 with the new URL rather than a silently broken redirect.

**Solution B — Change HTML redirect to 307 Temporary (reduces caching risk):**
```ruby
redirect_to profile_personal_best_path, status: :temporary_redirect
```
307 also preserves POST method/body but does not cache. Browsers re-evaluate the redirect on each request.

## Recommended Action

Apply both: Solution A for JSON clients + Solution B for HTML (use 307, not 308).

## Acceptance Criteria

- [ ] JSON `POST /settings/personal_best` returns 410 with `new_url` key
- [ ] HTML `POST /settings/personal_best` redirect does not cache permanently (307 or 303)
- [ ] `settings_controller_test.rb` tests JSON 410 response and HTML redirect status code

## Work Log

- 2026-03-08: Identified by security-sentinel (F-02) and agent-native-reviewer
