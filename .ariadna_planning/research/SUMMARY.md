# Research Summary: Asthma Buddy SaaS Foundation

**Domain:** SaaS foundation layer (MFA, RBAC, Billing, API) for health tracking app
**Researched:** 2026-03-14
**Overall confidence:** HIGH

## Executive Summary

Adding MFA, RBAC, Stripe billing, REST API, and integration tests to Asthma Buddy is well-supported by the existing Rails ecosystem. The codebase is cleanly structured with a custom authentication system (Authentication concern, Current.session pattern, Session model) that provides clear extension points for each feature. No major architectural rewrites are needed -- each feature adds new components and makes targeted modifications to existing ones.

The technology choices are straightforward and verified against current releases. Only 6 new gems are needed: 4 production (rotp v6.3, rqrcode v3.2, pundit v2.5, pay v11.4) and 2 test-only (webmock v3.26, vcr v6.4). All are mature, actively maintained, and compatible with Rails 8.1.2, SQLite3, Importmap, and Kamal deployment. No Redis, no Node.js, no additional infrastructure required. The existing Solid Queue handles Stripe webhook processing. The existing Rack::Attack handles API rate limiting.

The most important architectural insight is that RBAC must come first because every other feature depends on authorization policies. MFA modifies the authentication flow and should be second to harden security before exposing API keys or billing endpoints. The REST API is third because it creates a new attack surface that needs both RBAC policies and a mature auth system. Billing is last because it has the most external dependencies and benefits from all prior features being stable.

The primary risk areas are: the Pay gem's expectation of an `email` attribute when the app uses `email_address` (must alias immediately), modifying the authentication flow without breaking existing sessions (MFA), the admin boolean to role enum migration (two-phase approach required), and ensuring API key authentication goes through the same Pundit authorization policies as web requests.

## Key Findings

**Stack:** rotp v6.3 + rqrcode v3.2 for MFA, Pundit v2.5 for RBAC, Pay v11.4 (wraps Stripe) for billing, custom ApiKey model for API auth, webmock v3.26 + VCR v6.4 for test coverage. Total: 6 new gems, minimal footprint.

**Architecture:** Each feature adds new controllers/models while making targeted modifications to the Authentication concern and User model. Current.user pattern works for both session and API key auth paths. Pundit policies apply uniformly to web and API controllers.

**Critical pitfall:** Pay gem `email` vs `email_address` mismatch will silently break Stripe customer creation. Must add `alias_attribute :email, :email_address` before `pay_customer`.

## Implications for Roadmap

Based on research, suggested phase structure:

1. **RBAC (Role-Based Access Control)** - Foundation for all authorization decisions
   - Addresses: Role enum replacing admin boolean, Pundit policies for all resources
   - Avoids: Every subsequent feature needing ad-hoc authorization checks
   - Complexity: Low. Pure internal refactor with clear migration path.
   - Gems: pundit ~> 2.5

2. **MFA (TOTP + Recovery Codes)** - Security hardening before exposing new attack surfaces
   - Addresses: UK GDPR compliance posture for health data, user trust
   - Avoids: API keys existing before auth system is hardened
   - Complexity: Medium. Auth flow modification requires careful testing.
   - Gems: rotp ~> 6.3, rqrcode ~> 3.2

3. **REST API + API Key Authentication** - External data access interface
   - Addresses: GDPR data portability, future mobile app, integrations
   - Avoids: Building billing webhooks before API patterns are established
   - Complexity: Medium. New controllers but reuses existing authorization.
   - Gems: none (custom ApiKey model, ~50 lines of code)

4. **Stripe Subscription Billing** - Monetization
   - Addresses: Revenue, plan-based feature tiers, subscription lifecycle
   - Avoids: Premature billing before core SaaS features are stable
   - Complexity: High. External service dependency, webhook processing, edge cases.
   - Gems: pay ~> 11.4 (stripe gem installed as transitive dependency)

5. **Cross-Feature Integration Tests** - Verification
   - Addresses: Interactions between MFA + API, billing + feature gating, admin + all features
   - Each phase includes its own tests; this phase covers cross-cutting scenarios.
   - Gems: webmock ~> 3.26, vcr ~> 6.4 (test group only)

**Phase ordering rationale:**
- RBAC has zero external dependencies and is needed by everything else
- MFA must precede API keys (security hardening before new auth paths)
- API patterns (BaseController, versioning, rate limiting) inform webhook handling architecture
- Billing has the most risk and external coupling, so it benefits from stable internal features
- Testing infra (webmock/VCR) can be set up at any point but is most needed for billing phase

**Research flags for phases:**
- Phase 4 (Billing): Likely needs deeper research on Pay gem configuration, Stripe Checkout customization for UK market (VAT, GBP), and Customer Portal feature selection.
- Phase 3 (API): Needs design decisions on pagination convention, response format, and which resources to expose.
- Phase 2 (MFA): Needs careful auth flow design but patterns are well-documented. Unlikely to need additional research.
- Phase 1 (RBAC): Standard Pundit patterns, unlikely to need additional research.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All gem versions verified on RubyGems (rotp 6.3.0, rqrcode 3.2.0, pundit 2.5.2, pay 11.4.3, webmock 3.26.1, vcr 6.4.0). All confirmed Rails 8 compatible. |
| Features | HIGH | Feature list derived from existing codebase gaps and standard SaaS requirements. Dependencies mapped. |
| Architecture | HIGH | Based on direct codebase inspection. Integration points specific to actual file paths and patterns. |
| Pitfalls | HIGH | Derived from codebase analysis (email_address mismatch, admin boolean) + documented community issues. |

## Gaps to Address

- **Pay gem + SQLite at scale:** No explicit SQLite compatibility statement in Pay docs. Uses standard ActiveRecord so should work, but monitor `SQLITE_BUSY` errors in production. LOW confidence for high-traffic.
- **Pay gem email alias:** Need to verify `alias_attribute :email, :email_address` works with all Pay internal calls. Test in development console before committing.
- **Stripe UK-specific config:** VAT handling, GBP currency, UK billing address requirements need phase-specific research during billing implementation.
- **API pagination convention:** Cursor-based vs page-based for health data endpoints. Decision needed during API phase.
- **Caregiver delegated access:** Identified as differentiator but deferred. Requires its own research (consent model, delegation patterns, Pundit scoping for shared resources).
- **Pay gem migration tables:** Exact v11 schema should be verified by running `pay:install:migrations` in development early in billing phase.
