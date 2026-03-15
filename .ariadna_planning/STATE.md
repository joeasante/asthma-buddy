# Project State

## Project Reference

See: .ariadna_planning/PROJECT.md (updated 2026-03-14)

**Core value:** A reliable daily tracking companion that surfaces patterns — so users and their doctors actually understand what's happening with their asthma.
**Current focus:** Milestone 3 — SaaS Foundation (Phase 29: Stripe Billing)

## Current Position

Phase: 29 of 30 (Stripe Billing)
Plan: 04 complete
Status: Executing Phase 29
Last activity: 2026-03-15 — Plan 29-04 complete (Trial, pricing, lifecycle states, 818 tests)

Progress: ########░░ 80% (Milestone 3 — SaaS Foundation)

## Milestone 2 Summary (v2.0 — Complete 2026-03-14)

All 17 phases delivered (10-25, including 15.1):
- Phase 10-13: Medication data layer, management UI, dose logging, dose tracking & low stock
- Phase 14: Adherence dashboard (preventer compliance)
- Phase 15-15.1: Health events, reliever usage history
- Phase 16-17: Account management, legal, onboarding
- Phase 18-19: Temporary medication courses, notifications
- Phase 20-21: Legal pages, cookie banner, error pages, SEO & meta tags
- Phase 22: Request-path caching (Solid Cache)
- Phase 23: Compliance, security & accessibility (Rack::Attack, session timeout)
- Phase 24: Admin & observability (user tracking, admin panel, stats dashboard)
- Phase 25: Clinical intelligence (interpreted insights, 30-day Health Report, dose units)

Tests at close: 576

## Milestone 1 Summary (v1.0 — Complete)

All 9 phases delivered:
- Phase 1: Foundation (Rails, SQLite WAL, CI, Kamal)
- Phase 2: Authentication (signup, email verification, login, password reset)
- Phase 3-5: Symptom recording, management, timeline
- Phase 6-8: Peak flow recording, display, trends
- Phase 9: Dashboard

Tests at close: 195

## Performance Metrics

**Velocity:**
- Total plans completed: 12 (Milestone 3)
- Average duration: 4 min
- Total execution time: 54 min

| Phase | Plan | Duration | Tasks | Files |
|-------|------|----------|-------|-------|
| 26    | 01   | 13 min   | 3     | 52    |
| 26    | 02   | 4 min    | 2     | 20    |
| 27    | 01   | 4 min    | 2     | 8     |
| 27    | 02   | 6 min    | 2     | 15    |
| 27    | 03   | 3 min    | 2     | 4     |
| 28    | 01   | 2 min    | 2     | 9     |
| 28    | 02   | 4 min    | 2     | 14    |
| 28    | 03   | 1 min    | 1     | 2     |
| 29    | 01   | 4 min    | 2     | 11    |
| 29    | 02   | 4 min    | 2     | 6     |
| 29    | 03   | 1 min    | 2     | 0     |
| 29    | 04   | 8 min    | 8     | 22    |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- Research: RBAC first (zero deps), then MFA, API, Billing, Integration Tests
- Research: 6 new gems — rotp, rqrcode, pundit, pay, webmock, vcr
- Research: Pay gem needs `alias_attribute :email, :email_address` before `pay_customer`
- Research: MFA must use "pending" session state — don't authenticate before TOTP verification
- Research: Stripe webhooks must be async (SQLite single-writer constraint)
- 26-01: Used class_attribute :_skip_pundit for skip mechanism (cleaner than skip_after_action)
- 26-01: Kept require_admin in Admin::BaseController as defense-in-depth alongside Pundit
- 26-01: Used headless policies for non-model controllers (authorize :symbol, :action?)
- 26-01: Defined pundit_user mapping to Current.user (app uses Current.user, not current_user)
- 26-02: Kept ALLOWED_EMAILS for login restriction, SiteSetting only controls registration toggle
- 26-02: Used Rails.cache.fetch with 5-min TTL for registration_open? to avoid per-request DB queries
- 26-02: Used find_or_create_by! in toggle_registration! for resilience
- 27-01: Used AR Encryption (encrypts :otp_secret) for at-rest encryption of MFA secrets
- 27-01: Fixtures with AR Encryption fields must not store plaintext in YAML; enable MFA programmatically in tests
- 27-01: Recovery codes stored as comma-separated encrypted text, normalized on verification
- 27-02: Used controller: "security" in routes to fix Rails inflection of resource :security
- 27-02: Reused SettingsPolicy :show? for all security controller actions
- 27-02: Pending MFA session uses session[:pending_mfa_user_id] + session[:pending_mfa_at] with 5-min TTL
- 27-03: MFA enabled programmatically in test setup via enable_mfa! (AR Encryption fixture incompatibility)
- 27-03: Fixed mfa_challenge route controller resolution (singular resource needed controller: option)
- 28-01: One API key per user stored as SHA-256 digest on users table (no separate model)
- 28-01: Plaintext key passed via flash[:api_key] for one-time display after redirect
- 28-01: Reused SettingsPolicy :show? for API key controller authorization
- 28-02: Inherited from ActionController::API (not ApplicationController) for lightweight stateless API
- 28-02: Added user attribute to Current model with session fallback for API auth flow
- 28-02: Used recorded_at for HealthEvent API (plan had occurred_on which doesn't exist)
- 28-03: Throttle key is SHA-256 digest of Bearer token (matches stored digest)
- 28-03: Retry-After computed from throttle window reset time
- 28-03: API throttle response uses consistent JSON error format matching API controllers
- 29-01: Pay emails disabled for MVP (config.send_emails = false)
- 29-01: alias_attribute :email, :email_address before pay_customer for Pay gem compatibility
- 29-01: Admins always treated as premium regardless of subscription status
- 29-01: Pay::Stripe::Subscription STI type required when creating test records directly
- 29-02: button_to data-turbo=false goes on <button> element, not <form> — test selectors must match
- 29-02: Admins see "Premium (Admin)" but no manage subscription button (no Stripe subscription)
- 29-02: Policy gates: checkout for free only, portal for premium non-admin only
- 29-03: All feature gating code delivered by 29-01/29-02; plan 03 was verification-only pass
- 29-04: Paused subscriptions do NOT grant premium access (explicit !paused? check)
- 29-04: Health report JSON gated via premium?; HTML remains accessible to all
- 29-04: Trial reminder targets via Pay::Subscription query (status: trialing, 3-day window)
- 29-04: Pricing page uses allow_unauthenticated_access + skip_pundit for public access
- 29-04: Monthly price is default when no plan param provided to checkout

### Pending Todos

None yet.

### Blockers/Concerns

None yet.

## Session Continuity

Last session: 2026-03-15
Stopped at: Completed 29-04-PLAN.md (Trial, Pricing & Lifecycle)
Resume file: None
