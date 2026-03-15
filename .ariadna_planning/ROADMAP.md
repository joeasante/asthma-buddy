# Roadmap: Asthma Buddy — Milestone 3

## Overview

Milestone 3 transforms Asthma Buddy from a personal health tracker into a SaaS-ready platform. Five phases add role-based access control, multi-factor authentication, a versioned REST API, Stripe subscription billing, and cross-feature integration tests. When complete, the app authorizes every action via Pundit policies, protects health data with TOTP-based MFA, exposes all core resources via a rate-limited JSON API, accepts payments through Stripe, and gates premium features by subscription plan.

**Product vision:** Users log consistently enough that patterns emerge — reducing asthma attacks and improving medication adherence.
**Building for:** Person with asthma who wants frictionless daily logging — now extended to support multi-user SaaS with proper authorization, security, and monetization.
**Milestone 3 theme:** SaaS Foundation

---

## Phases

**Phase Numbering:**
- Integer phases (26–30): Planned Milestone 3 work
- Decimal phases (e.g. 26.1): Urgent insertions if needed (marked INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 26: Role-Based Access Control** — Replace admin boolean with role enum; authorize every action via Pundit policies
- [x] **Phase 27: Multi-Factor Authentication** — TOTP-based MFA with QR setup, recovery codes, and encrypted secrets
- [x] **Phase 28: REST API** — Versioned JSON API with key-based auth, pagination, filtering, and rate limiting
- [x] **Phase 29: Stripe Billing** — Subscription plans, Stripe Checkout, Customer Portal, webhook processing, feature gating, 30-day trial with auto-convert, pause-subscription option
- [ ] **Phase 30: Cross-Feature Integration Tests & Launch Prep** — Verify interactions between MFA, API, billing, and RBAC; FDA-safe copy review pass

---

## Phase Details

### Phase 26: Role-Based Access Control

**Goal**: Every controller action is authorized via Pundit policies, roles are managed through an extensible enum (not a boolean), and admins can control user access including toggling registration.
**Why this matters**: Authorization is the foundation every SaaS feature depends on — API endpoints, billing gating, and admin tools all need a consistent policy layer before they can exist.
**Depends on**: Milestone 2 complete (Phase 25)
**Requirements**: RBAC-01, RBAC-02, RBAC-03, RBAC-04

**Success Criteria** (what must be TRUE):
  1. An admin can navigate to the admin panel, see a list of users with their roles, and change a user's role between admin and member — the change takes effect immediately on that user's next request.
  2. Every controller action in the application runs through a Pundit policy; accessing a resource without authorization raises `Pundit::NotAuthorizedError` which renders a 403 or redirects with an error message.
  3. The existing admin panel, admin-only pages, and admin checks continue working identically after the migration from `admin` boolean to `role` enum — no existing functionality breaks.
  4. An admin can toggle registration open or closed from the admin panel; when closed, the signup page shows a "Registration is currently closed" message and the signup form is inaccessible.

**Plans:** 2 plans

Plans:
- [x] 26-01-PLAN.md — Role enum migration + Pundit policies on all controllers
- [x] 26-02-PLAN.md — Registration toggle + comprehensive RBAC test suite

---

### Phase 27: Multi-Factor Authentication

**Goal**: Users can protect their accounts with TOTP-based two-factor authentication, including setup via QR code, mandatory TOTP entry at login, recovery codes for emergency access, and the ability to disable MFA.
**Why this matters**: This is a health data app subject to UK GDPR — users need a second authentication factor to protect sensitive medical information, and it must be in place before API keys create a new programmatic access path.
**Depends on**: Phase 26 (Pundit policies gate MFA settings pages)
**Requirements**: MFA-01, MFA-02, MFA-03, MFA-04, MFA-05

**Success Criteria** (what must be TRUE):
  1. A logged-in user can navigate to their security settings, initiate MFA setup, scan a QR code with an authenticator app (e.g. Google Authenticator), enter a verification code, and have MFA enabled on their account.
  2. When an MFA-enabled user logs in with their password, they are held in a "pending MFA" state and must enter a valid TOTP code before gaining access to any authenticated page.
  3. Upon enabling MFA, the user is shown 10 one-time recovery codes and can download them as a text file; each recovery code can be used exactly once in place of a TOTP code.
  4. A user can disable MFA from their security settings after re-entering their password — subsequent logins no longer require a TOTP code.
  5. TOTP secrets and recovery codes are stored encrypted at rest; viewing the database directly does not reveal plaintext secrets.

**Plans:** 3 plans

Plans:
- [x] 27-01-PLAN.md — Gems, AR Encryption, MFA migration, User model MFA methods + tests
- [x] 27-02-PLAN.md — Routes, controllers (SecurityController, MfaChallengeController, SessionsController), views, settings Security card
- [x] 27-03-PLAN.md — Controller tests for MFA challenge, sessions, and security settings

---

### Phase 28: REST API

**Goal**: All core resources (symptom logs, peak flow readings, medications, dose logs, health events) are accessible via versioned JSON endpoints at `/api/v1/`, authenticated by API key, with consistent response formatting and rate limiting.
**Why this matters**: A JSON API enables GDPR data portability (users can extract their own health data programmatically), supports future mobile apps or integrations, and establishes the controller patterns that Stripe webhooks will reuse.
**Depends on**: Phase 26 (Pundit policies apply to API controllers), Phase 27 (auth hardened before exposing programmatic access)
**Requirements**: API-01, API-02, API-03, API-04, API-05, API-06

**Success Criteria** (what must be TRUE):
  1. A logged-in user can navigate to their settings, generate an API key that is displayed once, and the key is stored as a SHA-256 hash — the plaintext is never retrievable again.
  2. An API request with a valid Bearer token in the Authorization header returns the requested resource as JSON; a request with an invalid or missing token returns a 401 JSON error.
  3. GET requests to `/api/v1/symptom_logs`, `/api/v1/peak_flow_readings`, `/api/v1/medications`, `/api/v1/dose_logs`, and `/api/v1/health_events` return the current user's data in a consistent JSON format with pagination metadata.
  4. API responses support filtering (e.g. by date range) and return consistent error structures (status, error message, details) for 400, 401, 403, 404, and 422 responses.
  5. API requests exceeding the rate limit receive a 429 response with a Retry-After header; web requests are not affected by API rate limits.
  6. A user can revoke their API key from settings; subsequent API requests with that key return 401.

**Plans:** 3 plans

Plans:
- [x] 28-01-PLAN.md — API key infrastructure (migration, model concern, settings UI)
- [x] 28-02-PLAN.md — Versioned JSON API endpoints with auth, pagination, filtering
- [x] 28-03-PLAN.md — API-specific rate limiting via Rack::Attack

---

### Phase 29: Stripe Billing

**Goal**: The app offers free and premium subscription plans with feature limits, users can subscribe via Stripe Checkout with a 30-day free trial (auto-converts to paid), manage their subscription via Stripe Customer Portal (including pause option), and billing state is kept in sync through asynchronous webhook processing.
**Why this matters**: Billing is the monetization foundation that turns Asthma Buddy from a personal project into a sustainable product — without revenue, the app cannot grow or fund ongoing development and hosting.
**Depends on**: Phase 26 (Pundit policies for feature gating), Phase 28 (API patterns inform webhook controller design)
**Requirements**: BILL-01, BILL-02, BILL-03, BILL-04, BILL-05, BILL-06

**Pricing**: $7.99/month or $59.99/year (37% annual savings). 30-day free trial for new users (collects payment info upfront, auto-converts).

**Success Criteria** (what must be TRUE):
  1. The app defines free and premium plans; free users have visible feature limits (e.g. restricted API access, limited history, no PDF export) while premium users have full access.
  2. A free user can initiate a subscription upgrade, be redirected to Stripe Checkout (hosted payment page) with a 30-day free trial, complete signup, and return to the app as a premium subscriber — without the app handling card data directly.
  3. A subscribed user can access the Stripe Customer Portal from their billing settings to cancel, pause (1 or 3 months), update their payment method, or view invoices.
  4. Stripe webhook events (subscription created, updated, cancelled, paused, resumed, payment failed) are processed asynchronously via Solid Queue with idempotency — duplicate webhook deliveries do not create duplicate state changes.
  5. Premium-only features are gated by subscription plan using Pundit policies; a user who downgrades or cancels loses access to premium features gracefully (with a clear upgrade prompt, not an error).
  6. The billing settings page shows the user's current plan name, subscription status (active, trialing, paused, cancelled, past due), next billing date, and trial end date if applicable.
  7. Trial reminder email is sent 3 days before the trial ends, clearly stating the charge amount and how to cancel.

**Plans:** 4 plans

Plans:
- [x] 29-01-PLAN.md — Pay gem setup, migrations, User model integration, PlanLimits concern
- [x] 29-02-PLAN.md — Billing settings controller, views, policy, settings navigation
- [x] 29-03-PLAN.md — Feature gating (API keys, history limits) with upgrade prompts
- [x] 29-04-PLAN.md — 30-day trial, monthly/annual pricing, public pricing page, paused state, trial reminder emails

---

### Phase 30: Cross-Feature Integration Tests & Launch Prep

**Goal**: Integration tests verify the correct interactions between all Milestone 3 features — MFA with API keys, billing with feature gating, RBAC parity across web and API, and Stripe webhook processing with test fixtures. Additionally, a copy review pass ensures all user-facing text avoids FDA medical device classification.
**Why this matters**: Each phase includes its own unit and controller tests, but the cross-cutting interactions (Does MFA block API access? Does downgrading revoke API-gated features? Do API endpoints enforce the same Pundit policies as web?) are where bugs hide. The copy review prevents regulatory risk before launch.
**Depends on**: Phase 26, Phase 27, Phase 28, Phase 29 (all features must exist before integration testing)
**Requirements**: TEST-01, TEST-02, TEST-03, TEST-04

**Success Criteria** (what must be TRUE):
  1. Tests confirm that API key authentication bypasses MFA (by design) — a user with MFA enabled can use their API key without entering a TOTP code, while web login still requires MFA.
  2. Tests confirm that upgrading from free to premium grants access to gated features, and downgrading or cancelling removes access — across both web and API.
  3. Tests confirm that Pundit policies produce identical authorization decisions for the same user/resource whether accessed via web controller or API controller.
  4. Stripe webhook test fixtures (via WebMock/VCR) verify that subscription lifecycle events (created, updated, cancelled, paused, resumed, payment_failed) are processed correctly without hitting the Stripe API.
  5. All user-facing text has been reviewed to avoid medical device classification language — no "diagnose," "treat," "prescribe," or "medical advice." Only "track," "monitor," "understand," "informational."

**Plans**: TBD

---

## Progress

**Execution Order:**
Phases execute in numeric order: 26 -> 27 -> 28 -> 29 -> 30

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 26. Role-Based Access Control | 2/2 | ✓ Complete | 2026-03-14 |
| 27. Multi-Factor Authentication | 3/3 | ✓ Complete | 2026-03-14 |
| 28. REST API | 3/3 | ✓ Complete | 2026-03-14 |
| 29. Stripe Billing | 4/4 | ✓ Complete | 2026-03-15 |
| 30. Cross-Feature Integration Tests | 0/TBD | Not started | - |

---

## Requirement Coverage

**Milestone 3 — 22 requirements — 22 mapped — 0 unmapped**

| Requirement | Phase |
|-------------|-------|
| RBAC-01 | Phase 26 |
| RBAC-02 | Phase 26 |
| RBAC-03 | Phase 26 |
| RBAC-04 | Phase 26 |
| MFA-01 | Phase 27 |
| MFA-02 | Phase 27 |
| MFA-03 | Phase 27 |
| MFA-04 | Phase 27 |
| MFA-05 | Phase 27 |
| API-01 | Phase 28 |
| API-02 | Phase 28 |
| API-03 | Phase 28 |
| API-04 | Phase 28 |
| API-05 | Phase 28 |
| API-06 | Phase 28 |
| BILL-01 | Phase 29 |
| BILL-02 | Phase 29 |
| BILL-03 | Phase 29 |
| BILL-04 | Phase 29 |
| BILL-05 | Phase 29 |
| BILL-06 | Phase 29 |
| TEST-01 | Phase 30 |
| TEST-02 | Phase 30 |
| TEST-03 | Phase 30 |
| TEST-04 | Phase 30 |

---

*Roadmap created: 2026-03-14 — Milestone 3 (SaaS Foundation)*
*Milestones 1-2 (Phases 1-25) archived — all 26 phases complete (including 15.1)*

---

## Milestone 4 — Feature Expansion & Accessibility (Planned)

**Theme:** Close competitive gaps, ensure accessibility, and add polish.

**Pricing context:** $7.99/mo or $59.99/yr. Freemium with 30-day trial. Free tier: core tracking with 30-day history. Premium: unlimited history, API, PDF export.

### Planned Phases (to be detailed when Milestone 3 completes)

| Priority | Phase | Feature | Notes |
|----------|-------|---------|-------|
| High | 31 | Air Quality / Pollen / Weather Integration | Real-time environmental data with trigger alerts. #1 missing feature vs competitors. |
| High | 32 | Asthma Action Plan | Digital green/yellow/red zone plans — clinical standard |
| High | 33 | PDF/CSV Health Report Export | Doctors want PDF, not JSON. Email share included. Premium feature. |
| High | 34 | Apple HealthKit Integration | Table stakes for health apps. Critical as Apple expands asthma features. |
| Medium | 35 | Trigger Correlation Analysis | Track triggers, correlate with symptom episodes over time |
| Medium | 36 | Multi-User / Family Support | Parents managing children's asthma |
| Medium | 37 | Gamification | Streaks, challenges, rewards for engagement. Helps with 7.5% monthly churn. |
| Medium | 38 | Dark Mode | Full dark mode support across all views |
| Medium | 39 | WCAG 2.2 Compliance | Full accessibility audit and remediation |
| Medium | 40 | Inhaler Technique Training Videos | Educational content — last medium priority item |
| Low | 41 | AI Chat (optional) | Conversational asthma assistant. Only if demand warrants. Requires disclaimers. |

### Backlog (post-launch, demand-driven)
- HSA/FSA eligibility (LMN templates, Truemed integration)
- Regional/PPP-adjusted pricing
- Clinician portal (only if B2B2C demand emerges)

*Milestone 4 planned: 2026-03-15 — informed by competitive research and pricing strategy*
