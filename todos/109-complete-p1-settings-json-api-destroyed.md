---
status: pending
priority: p1
issue_id: "109"
tags: [code-review, api, agent-native, settings, rails, json]
dependencies: []
---

# Settings JSON API destroyed — `GET /settings.json` and `POST /settings/personal_best.json` return 301

## Problem Statement

The old `SettingsController` served a JSON API used by automated agents: `GET /settings.json` returned current personal best data, and `POST /settings/personal_best.json` created a personal best record. Both now return `301 Moved Permanently` to HTML-only profile routes. Any agent or script calling these endpoints will receive an HTML redirect response, not JSON, breaking the agent-native contract established in `ApplicationController`'s documentation.

Additionally, `POST /settings/personal_best` redirecting with `301` (instead of `308`) means browsers and HTTP clients convert the follow-up request to a `GET`, dropping the POST body entirely.

## Findings

- `app/controllers/settings_controller.rb` — `show` returns `redirect_to profile_path, status: :moved_permanently` — HTML redirect, no `format.json` response
- `app/controllers/settings_controller.rb` — `update_personal_best` returns `redirect_to profile_personal_best_path, status: :moved_permanently` — 301 on POST converts to GET
- `app/controllers/profiles_controller.rb` — `update_personal_best` has no `respond_to` block with `format.json`
- The settings routes are still present in `config/routes.rb` so the endpoints exist but return incorrect responses

## Proposed Solutions

### Option A: Add format.json to ProfilesController + 308 on settings POST redirect (Recommended)

Fix both issues:
1. Add `respond_to` in `ProfilesController#update_personal_best` with `format.json` response
2. Change `SettingsController#update_personal_best` to `status: :permanent_redirect` (308) instead of 301
3. Add `format.json` to `SettingsController#show` that proxies or redirects to the JSON API on profiles

**Effort:** Small | **Risk:** Low

### Option B: Keep settings routes as JSON-only aliases
Update `SettingsController` to serve JSON responses for the old endpoints (read personal best, create personal best) by calling the same service objects as `ProfilesController`, while redirecting HTML requests to the profile page.

**Effort:** Medium | **Risk:** Low

## Recommended Action

Option A — fix the status code and add JSON support to the recipient controller.

## Technical Details

- **Affected files:** `app/controllers/settings_controller.rb`, `app/controllers/profiles_controller.rb`
- **HTTP status:** 301 converts POST→GET (RFC 7231 §6.4.2); 308 preserves method (RFC 7538)

## Acceptance Criteria

- [ ] `GET /settings.json` returns JSON (personal best data) not HTML redirect
- [ ] `POST /settings/personal_best.json` returns JSON not a 301/redirect
- [ ] `POST /settings/personal_best` redirect uses 308 not 301 (body preserved)
- [ ] `ProfilesController#update_personal_best` returns JSON on `format.json`
- [ ] Test in `settings_controller_test.rb` covers JSON format response

## Work Log

- 2026-03-08: Identified by agent-native-reviewer and architecture-strategist during PR review
