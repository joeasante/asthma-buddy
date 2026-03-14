---
phase: 28-rest-api
verified: 2026-03-14T21:24:33Z
status: passed
score: 14/14 must-haves verified | security: 0 critical, 0 high | performance: 0 high
must_haves:
  truths:
    - "User can generate an API key from settings; key is displayed once"
    - "API key is stored as a SHA-256 hash; plaintext is never retrievable after generation"
    - "User can revoke their API key from settings"
    - "After revocation, the api_key_digest is nil"
    - "API request with valid Bearer token returns JSON data"
    - "API request with invalid or missing token returns 401 JSON error"
    - "GET /api/v1/symptom_logs returns current user's symptom logs with pagination"
    - "GET /api/v1/peak_flow_readings returns current user's peak flow readings with pagination"
    - "GET /api/v1/medications returns current user's medications with pagination"
    - "GET /api/v1/dose_logs returns current user's dose logs with pagination"
    - "GET /api/v1/health_events returns current user's health events with pagination"
    - "API responses support date range filtering"
    - "API error responses follow consistent format with status, message, details"
    - "API requests exceeding rate limit receive 429 with Retry-After header"
  artifacts:
    - path: "app/models/concerns/api_authenticatable.rb"
      exists: true
      substantive: true
      wired: true
    - path: "app/controllers/api/v1/base_controller.rb"
      exists: true
      substantive: true
      wired: true
    - path: "app/controllers/api/v1/symptom_logs_controller.rb"
      exists: true
      substantive: true
      wired: true
    - path: "app/controllers/api/v1/peak_flow_readings_controller.rb"
      exists: true
      substantive: true
      wired: true
    - path: "app/controllers/api/v1/medications_controller.rb"
      exists: true
      substantive: true
      wired: true
    - path: "app/controllers/api/v1/dose_logs_controller.rb"
      exists: true
      substantive: true
      wired: true
    - path: "app/controllers/api/v1/health_events_controller.rb"
      exists: true
      substantive: true
      wired: true
    - path: "app/controllers/settings/api_keys_controller.rb"
      exists: true
      substantive: true
      wired: true
    - path: "app/views/settings/api_keys/show.html.erb"
      exists: true
      substantive: true
      wired: true
    - path: "config/initializers/rack_attack.rb"
      exists: true
      substantive: true
      wired: true
    - path: "db/migrate/20260314211111_add_api_key_columns_to_users.rb"
      exists: true
      substantive: true
      wired: true
  key_links:
    - from: "app/controllers/api/v1/base_controller.rb"
      to: "User.authenticate_by_api_key"
      verified: true
    - from: "app/controllers/api/v1/base_controller.rb"
      to: "Pundit::Authorization"
      verified: true
    - from: "config/routes.rb"
      to: "Api::V1::*Controller"
      verified: true
    - from: "app/controllers/settings/api_keys_controller.rb"
      to: "User#generate_api_key!"
      verified: true
    - from: "app/views/settings/show.html.erb"
      to: "settings/api_keys#show"
      verified: true
    - from: "config/initializers/rack_attack.rb"
      to: "API endpoints"
      verified: true
human_verification:
  - test: "Generate an API key from Settings > API Key, verify it displays once"
    expected: "Key shown in monospace code block with Copy button; revisiting page shows Active badge but not the key"
    why_human: "Visual display and clipboard interaction cannot be verified programmatically"
  - test: "Make API requests via curl to all 5 endpoints with a valid Bearer token"
    expected: "JSON responses with data array and meta pagination object"
    why_human: "End-to-end HTTP behavior against running server confirms full stack works"
---

# Phase 28: REST API Verification Report

**Phase Goal:** All core resources (symptom logs, peak flow readings, medications, dose logs, health events) are accessible via versioned JSON endpoints at /api/v1/, authenticated by API key, with consistent response formatting and rate limiting.
**Verified:** 2026-03-14T21:24:33Z
**Status:** passed
**Re-verification:** No -- initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | User can generate an API key from settings; key is displayed once | VERIFIED | Settings::ApiKeysController#create calls generate_api_key!, stores plaintext in flash[:api_key]; view renders it in code block only when flash present |
| 2 | API key is stored as SHA-256 hash; plaintext never retrievable | VERIFIED | ApiAuthenticatable#generate_api_key! uses Digest::SHA256.hexdigest; only digest stored in DB; 12 model tests confirm |
| 3 | User can revoke their API key from settings | VERIFIED | Settings::ApiKeysController#destroy calls revoke_api_key!; view has delete button with turbo_confirm |
| 4 | After revocation, api_key_digest is nil | VERIFIED | ApiAuthenticatable#revoke_api_key! sets both columns to nil; model test confirms |
| 5 | API request with valid Bearer token returns JSON data | VERIFIED | BaseController#authenticate_api_key! extracts Bearer token, calls User.authenticate_by_api_key, sets Current.user; 62 API tests pass |
| 6 | API request with invalid/missing token returns 401 JSON error | VERIFIED | BaseController renders 401 with consistent error format; test coverage for missing header, invalid token, revoked key |
| 7 | GET /api/v1/symptom_logs returns user's logs with pagination | VERIFIED | SymptomLogsController#index uses policy_scope, date_filter, paginate; 20 tests pass |
| 8 | GET /api/v1/peak_flow_readings returns user's readings with pagination | VERIFIED | PeakFlowReadingsController#index uses policy_scope, date_filter, paginate; 10 tests pass |
| 9 | GET /api/v1/medications returns user's medications with pagination | VERIFIED | MedicationsController#index uses policy_scope with .includes(:dose_logs), paginate; 10 tests pass |
| 10 | GET /api/v1/dose_logs returns user's dose logs with pagination | VERIFIED | DoseLogsController#index uses policy_scope with .includes(:medication), date_filter, paginate; 11 tests pass |
| 11 | GET /api/v1/health_events returns user's health events with pagination | VERIFIED | HealthEventsController#index uses policy_scope, date_filter, paginate; 11 tests pass |
| 12 | API responses support date range filtering | VERIFIED | BaseController#date_filter handles date_from/date_to with Date.parse, returns 400 on invalid dates; tested across all filterable endpoints |
| 13 | API error responses follow consistent format | VERIFIED | BaseController#render_error produces { error: { status, message, details } }; rescue_from handlers for Pundit::NotAuthorizedError (403) and RecordNotFound (404) |
| 14 | API requests exceeding rate limit receive 429 with Retry-After | VERIFIED | Rack::Attack throttle "api/v1/requests" at 60/min per API key digest; throttled_responder returns JSON error with Retry-After header; 6 tests pass |

**Score:** 14/14 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `app/models/concerns/api_authenticatable.rb` | API key generation, hashing, authentication | VERIFIED | 33 lines; generate_api_key!, revoke_api_key!, api_key_active?, self.authenticate_by_api_key |
| `app/controllers/api/v1/base_controller.rb` | Base controller with Bearer auth, pagination, error handling | VERIFIED | 84 lines; inherits ActionController::API, includes Pundit, Bearer extraction, paginate, date_filter, render_error |
| `app/controllers/api/v1/symptom_logs_controller.rb` | Symptom logs endpoint | VERIFIED | 31 lines; authorize, policy_scope, date_filter, paginate, render json |
| `app/controllers/api/v1/peak_flow_readings_controller.rb` | Peak flow readings endpoint | VERIFIED | 31 lines; same pattern |
| `app/controllers/api/v1/medications_controller.rb` | Medications endpoint | VERIFIED | 31 lines; includes(:dose_logs) for N+1 prevention |
| `app/controllers/api/v1/dose_logs_controller.rb` | Dose logs endpoint | VERIFIED | 31 lines; includes(:medication), medication_name from association |
| `app/controllers/api/v1/health_events_controller.rb` | Health events endpoint | VERIFIED | 29 lines; uses recorded_at (not occurred_on, which doesn't exist) |
| `app/controllers/settings/api_keys_controller.rb` | Settings UI controller | VERIFIED | 21 lines; show, create, destroy actions |
| `app/views/settings/api_keys/show.html.erb` | API key management page | VERIFIED | 79 lines; one-time key display via flash, active state, generate/revoke buttons, design system styling |
| `config/initializers/rack_attack.rb` | API rate limiting rules | VERIFIED | Throttle "api/v1/requests" at 60/min per API key digest; JSON 429 responder with Retry-After |
| `db/migrate/20260314211111_add_api_key_columns_to_users.rb` | api_key_digest and api_key_created_at on users | VERIFIED | add_column x2, unique index on api_key_digest |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| base_controller.rb | User.authenticate_by_api_key | Bearer token extraction + model lookup | WIRED | Line 33: `User.authenticate_by_api_key(token)` |
| base_controller.rb | Pundit::Authorization | include + after_action | WIRED | Line 6: `include Pundit::Authorization`; Line 8: `after_action :verify_authorized` |
| config/routes.rb | Api::V1::*Controller | namespace :api / namespace :v1 | WIRED | Lines 4-12: all 5 resources defined |
| api_keys_controller.rb | User#generate_api_key! | model method call in create action | WIRED | Line 12: `Current.user.generate_api_key!` |
| settings/show.html.erb | settings/api_keys#show | navigation link | WIRED | Line 69: `settings_api_key_path` |
| rack_attack.rb | API endpoints | path matching + key extraction | WIRED | Line 32: `req.path.start_with?("/api/v1/")` with SHA-256 digest throttle key |
| user.rb | ApiAuthenticatable | include concern | WIRED | Line 4: `include ApiAuthenticatable` |
| current.rb | user attribute | direct assignment for API flow | WIRED | Line 4: `attribute :session, :user` with fallback in `def user` |

### Requirements Coverage

| Requirement | Status | Evidence |
|-------------|--------|----------|
| API-01: User can generate API key, shown once, SHA-256 stored | SATISFIED | ApiAuthenticatable + Settings UI verified |
| API-02: Bearer token authentication | SATISFIED | BaseController#authenticate_api_key! verified |
| API-03: Versioned endpoints at /api/v1/ for all 5 resources | SATISFIED | All 5 controllers + routes verified |
| API-04: Consistent JSON format with pagination, filtering, error handling | SATISFIED | { data, meta } envelope, date_from/date_to, { error } format verified |
| API-05: Rate limiting separate from web requests | SATISFIED | Rack::Attack per-API-key throttle, web requests unaffected (tested) |
| API-06: User can revoke API key from settings | SATISFIED | Settings::ApiKeysController#destroy + revoke_api_key! verified |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| None found | - | - | - | - |

No TODOs, FIXMEs, placeholders, debug statements, empty implementations, or NotImplementedError found in any phase 28 files.

### Security Findings

| Check | Name | Severity | File | Line | Detail |
|-------|------|----------|------|------|--------|
| 1.1a | String interpolation in SQL | Low (false positive) | base_controller.rb | 65, 70 | `date_column` is a developer-controlled symbol kwarg (`:recorded_at`), never from user input |

**Security:** 1 finding (0 critical, 0 high, 1 low/false-positive)

Notes:
- All endpoints use `policy_scope` -- no unscoped finds (IDOR safe)
- No `params.permit!` -- no mass assignment risk
- API controllers inherit ActionController::API (no session, no CSRF needed)
- API key stored as SHA-256 digest (plaintext never persisted)
- No hardcoded secrets found

### Performance Findings

| Check | Name | Severity | File | Line | Detail |
|-------|------|----------|------|------|--------|
| None | - | - | - | - | - |

**Performance:** 0 findings

Notes:
- Medications controller uses `.includes(:dose_logs)` to prevent N+1
- Dose logs controller uses `.includes(:medication)` to prevent N+1
- Pagination caps per_page at 100

### Human Verification Required

### 1. API Key One-Time Display

**Test:** Navigate to Settings > API Key, click "Generate API Key", verify the key appears in a monospace code block. Click "Copy" and verify clipboard. Navigate away and return -- key should not be shown again.
**Expected:** Key displayed once with Copy button; subsequent visits show "Active" badge and created date but not the key.
**Why human:** Visual display, clipboard interaction, and flash-based one-time behavior need browser testing.

### 2. End-to-End API Requests

**Test:** Generate an API key, then use curl with Bearer token to hit all 5 endpoints. Also test with no token, invalid token, and date filtering params.
**Expected:** Valid token returns 200 with { data, meta } JSON. Invalid/missing token returns 401 with { error } JSON. Date filtering narrows results.
**Why human:** Full-stack HTTP behavior against a running server confirms everything works together.

### Tests Executed

82 tests, 248 assertions, 0 failures, 0 errors:
- 12 model tests (user_api_key_test.rb)
- 8 controller tests (settings/api_keys_controller_test.rb)
- 20 tests (api/v1/symptom_logs_controller_test.rb)
- 10 tests (api/v1/peak_flow_readings_controller_test.rb)
- 10 tests (api/v1/medications_controller_test.rb)
- 11 tests (api/v1/dose_logs_controller_test.rb)
- 11 tests (api/v1/health_events_controller_test.rb)
- 6 tests (api/v1/rate_limiting_test.rb)

---

_Verified: 2026-03-14T21:24:33Z_
_Verifier: Claude (ariadna-verifier)_
