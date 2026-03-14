# Feature Landscape

**Domain:** SaaS security/billing/API for health tracking app
**Researched:** 2026-03-14

## Table Stakes

Features expected in a SaaS health app. Missing = security/compliance risk or blocked functionality.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| TOTP MFA setup/disable | Health data (UK GDPR special category) demands strong auth. Users expect 2FA on health apps. | Medium | Requires authenticator app flow + QR code |
| MFA recovery codes | Users will lose phones. No recovery = locked out of health data. | Low | Generate 10 codes, store hashed, mark used |
| MFA challenge on login | Core security feature. Without this, MFA setup is theater. | Medium | Intercepts login flow, must not break existing sessions |
| Role-based access (admin/member) | Already have admin boolean. Need proper roles for feature gating and future clinician access. | Low | Enum column + Pundit policies |
| API key generation/revocation | Users need programmatic access to export their health data (UK GDPR data portability). | Medium | Secure token generation, digest storage, management UI |
| REST API for health data | Data portability requirement. Also enables future mobile app or integrations. | Medium | Versioned JSON endpoints for all health resources |
| Stripe subscription checkout | If monetizing, need payment flow. Stripe Checkout is expected UX. | Medium | Pay gem handles most complexity |
| Subscription management (cancel/resume) | Users expect self-service billing management. | Low | Stripe Customer Portal handles this |
| Webhook processing | Subscriptions change state asynchronously. Without webhooks, billing state drifts. | Medium | Pay gem handles core webhooks out of the box |
| Feature gating by plan | Different tiers need different feature access. | Low | Policy-based checks in controllers |

## Differentiators

Features not expected but add significant value.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Clinician role with read access | Allow a user's clinician to view their health data (with consent). Unique for personal health apps. | High | Requires consent model, invitation flow, scoped read access |
| API rate limiting per key | Professional API behavior. Prevents abuse. | Low | Rack::Attack already in Gemfile, just add API key scoping |
| Audit log for sensitive actions | Track MFA changes, API key creation, billing changes. Important for health data compliance. | Medium | New AuditLog model, concern for tracking |
| Enforce MFA for all users (admin control) | Admin can require MFA for all accounts. Important for shared/clinical deployments. | Low | Admin setting + before_action check |
| API scopes (read-only vs read-write) | Granular API key permissions. Lets users create limited keys for specific integrations. | Medium | Scopes column on ApiKey, policy integration |
| Usage-based billing metering | Track API calls or data volume for tiered pricing. | High | Requires metering infrastructure |

## Anti-Features

Features to explicitly NOT build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| SMS-based 2FA | Expensive, SIM-swap vulnerable, requires SMS provider. TOTP is more secure and free. | TOTP only with recovery codes. |
| OAuth provider (be an OAuth server) | Massive complexity, security surface. This is a personal health app, not a platform. | Simple API keys with Bearer token auth. |
| Multi-tenancy / organization accounts | Premature architecture. Current app is single-user per account. | Keep single-user model. Add clinician role as explicit data-sharing consent. |
| Custom billing portal | Stripe Customer Portal handles plan changes, payment method updates, invoices. Building custom is months of work. | Use Stripe Customer Portal via redirect. |
| GraphQL API | Adds query complexity, N+1 risks, no clear benefit for this data model. REST is simpler and sufficient. | REST API with JSON endpoints. |
| JWT authentication | Adds refresh token complexity, revocation challenges. API keys are simpler and sufficient for this use case. | Hashed API keys with Bearer token auth. |
| Passwordless / magic link auth | Nice UX but adds complexity to auth flow. Current password + MFA is secure enough. | Keep has_secure_password + TOTP MFA. |

## Feature Dependencies

```
RBAC (role enum + Pundit)
  --> MFA (policies control who can enforce MFA)
  --> API (policies control API access per role)
  --> Billing (plan tiers map to feature permissions)

MFA (TOTP setup + challenge)
  --> API Keys (design: API keys bypass MFA by intent)

API Keys + API Endpoints
  --> Billing feature gating (API access may be plan-gated)

Billing (Pay + Stripe)
  --> Feature gating (Subscribable concern uses RBAC policies)
```

## MVP Recommendation

Prioritize:
1. **RBAC** -- Foundation for all authorization. Low complexity, high leverage.
2. **MFA (TOTP + recovery codes)** -- Security requirement for health data. Medium complexity but critical for UK GDPR compliance posture.
3. **REST API + API keys** -- Data portability (GDPR right). Enables future integrations.
4. **Stripe billing** -- Monetization path. Defer if not immediately needed.

Defer:
- **Clinician role**: Complex consent model. Build after core SaaS features are solid.
- **API scopes**: Start with full-access API keys. Add scopes when real usage patterns emerge.
- **Audit logging**: Important but can be added incrementally. Start with logging MFA and billing changes only.
- **Usage-based billing**: Only relevant at scale. Start with flat-rate tiers.

## Sources

- UK GDPR special category data requirements for health apps
- [Stripe Customer Portal](https://docs.stripe.com/customer-management)
- [Pay gem feature set](https://github.com/pay-rails/pay)
- Existing codebase analysis (admin boolean, ALLOWED_EMAILS pattern)
