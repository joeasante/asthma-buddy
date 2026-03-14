# Project State

## Project Reference

See: .ariadna_planning/PROJECT.md (updated 2026-03-14)

**Core value:** A reliable daily tracking companion that surfaces patterns — so users and their doctors actually understand what's happening with their asthma.
**Current focus:** Milestone 3 — SaaS Foundation (Phase 27: Multi-Factor Authentication)

## Current Position

Phase: 27 of 30 (Multi-Factor Authentication)
Plan: 01 complete
Status: Executing Phase 27
Last activity: 2026-03-14 — Phase 27 Plan 01 executed (MFA data layer, model methods, unit tests)

Progress: ###░░░░░░░ 30% (Milestone 3 — SaaS Foundation)

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
- Total plans completed: 3 (Milestone 3)
- Average duration: 7 min
- Total execution time: 21 min

| Phase | Plan | Duration | Tasks | Files |
|-------|------|----------|-------|-------|
| 26    | 01   | 13 min   | 3     | 52    |
| 26    | 02   | 4 min    | 2     | 20    |
| 27    | 01   | 4 min    | 2     | 8     |

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

### Pending Todos

None yet.

### Blockers/Concerns

None yet.

## Session Continuity

Last session: 2026-03-14
Stopped at: Completed 27-01-PLAN.md
Resume file: None
