# Technology Stack

**Project:** Asthma Buddy -- SaaS Foundation (MFA, RBAC, Billing, API, Testing)
**Researched:** 2026-03-14
**Overall confidence:** HIGH

## Existing Stack (Do Not Change)

| Technology | Version | Purpose |
|------------|---------|---------|
| Rails | 8.1.2 | Framework |
| Ruby | 4.0.1 | Language |
| SQLite3 | >= 2.1 | Database (WAL mode) |
| Propshaft | latest | Asset pipeline |
| Importmap | latest | JS module loading (no Node) |
| Hotwire | latest | Turbo + Stimulus |
| bcrypt | ~> 3.1.7 | has_secure_password |
| Rack::Attack | latest | Rate limiting |
| Solid Queue/Cache/Cable | latest | Background jobs, cache, websockets |
| Kamal | latest | Deployment |
| Minitest + Capybara + Selenium | latest | Testing |
| jbuilder | latest | JSON rendering (already in Gemfile) |

## New Dependencies

### MFA / TOTP

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| rotp | ~> 6.3 | TOTP generation and verification (RFC 6238) | The standard Ruby TOTP library. Mature, zero dependencies, 6.3.0 is latest stable (Aug 2023, but stable/complete -- TOTP is a finished spec). Used by virtually every Rails app implementing TOTP. Compatible with Google Authenticator, Authy, 1Password. No alternative comes close in adoption or simplicity. |
| rqrcode | ~> 3.2 | QR code generation for authenticator app setup | Generates SVG/PNG QR codes inline. 3.2.0 is latest (Jan 2026). Pure Ruby, no system dependencies. Needed to show provisioning URI as scannable QR during MFA enrollment. |

**Implementation notes:**
- Store encrypted TOTP secret on User model (use Active Record encryption, built into Rails 8)
- Store backup codes as encrypted JSON array on User model, or as separate RecoveryCode model
- No need for a separate gem -- rotp + rqrcode + Rails built-in encryption covers everything
- Recovery codes: generate 10 random codes, bcrypt-hash them, allow one-time use

**Confidence:** HIGH -- rotp is the undisputed standard for TOTP in Ruby. rqrcode version verified on RubyGems.

### Role-Based Access Control (RBAC)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| pundit | ~> 2.5 | Authorization policy objects | Pundit over CanCanCan because: (1) policy-per-model maps cleanly to this app's existing controller structure, (2) no DSL magic -- plain Ruby classes, easy to test, (3) works with any auth system including Rails 8 built-in auth, (4) 2.5.2 is latest (Sept 2025), actively maintained. CanCanCan centralizes everything in one Ability class which becomes unwieldy. |

**Implementation notes:**
- Replace the existing `admin` boolean with an enum role column: `enum :role, { patient: 0, caregiver: 1, clinician: 2, admin: 3 }`
- Pundit policies go in `app/policies/` -- one per model/controller
- Override `pundit_user` to return `Current.user` (Rails 8 auth pattern)
- No Rolify needed -- a single role enum is sufficient for this app's needs (one role per user, no many-to-many role assignments)

**Confidence:** HIGH -- Pundit is the most widely recommended authorization gem for Rails apps not using Devise. Version verified on RubyGems.

### Stripe Subscription Billing

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| pay | ~> 11.4 | Stripe billing integration (subscriptions, webhooks, customer portal) | Pay over raw stripe gem because: (1) handles webhook routing, signature verification, and event processing out of the box, (2) manages Stripe Customer lifecycle (create, sync, update) automatically, (3) provides `pay_customer` concern and database-backed subscription/charge models, (4) SCA (Strong Customer Authentication) support built in, (5) uses Stripe Checkout and Customer Portal -- no custom payment forms needed, (6) 11.4.3 is latest (Dec 2025), requires Rails 7.0+, actively maintained by Chris Oliver (GoRails). Direct stripe gem usage would require reimplementing all of this. |
| stripe | (transitive) | Stripe API client | Installed automatically as pay dependency. No need to add separately. |

**Implementation notes:**
- Pay creates its own migration tables (`pay_customers`, `pay_subscriptions`, `pay_charges`, `pay_merchants`, `pay_webhooks`)
- These are SQLite-compatible -- Pay uses standard Active Record, no Postgres-specific features
- Webhook endpoint is mounted automatically via Pay's engine
- Use Stripe Checkout for payment collection (hosted by Stripe, PCI compliant, no custom forms)
- Use Stripe Customer Portal for subscription management (cancel, upgrade, payment method changes)
- Plans defined in Rails config, synced to Stripe products/prices
- Solid Queue handles async webhook processing
- **Critical:** User model uses `email_address` but Pay expects `email`. Must add `alias_attribute :email, :email_address`

**Confidence:** HIGH -- Pay is the standard Rails billing gem. Version verified on RubyGems.

### REST API Authentication

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| (none -- roll your own) | n/a | API key model + Bearer token auth | The api_keys gem (v0.2.1, Aug 2025) is too young (pre-1.0) and brings a full mounted dashboard/engine that is overkill for a health app's API. API key auth is straightforward to build: (1) ApiKey model with `token_digest` (SHA256), `user_id`, `name`, `expires_at`, `last_used_at`, (2) `before_action` in API base controller that authenticates via `Authorization: Bearer <token>`, (3) rate limiting already handled by Rack::Attack. This is ~50 lines of code, fully under our control, no dependency risk. |

**Implementation notes:**
- Generate tokens with `SecureRandom.hex(32)` -- show raw token once at creation, store SHA256 digest
- API controllers namespaced under `Api::V1::` with `ActionController::API` base class
- Use jbuilder (already in Gemfile) for JSON responses
- Pundit policies apply to API controllers too -- same authorization layer
- API versioning via URL path (`/api/v1/`)
- No JWT -- API keys are simpler, revocable, and appropriate for a server-to-server or personal API key use case

**Confidence:** HIGH -- this is a well-established pattern. API key auth does not warrant a gem dependency.

### Integration & System Test Coverage

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| webmock | ~> 3.26 | Stub HTTP requests in tests | Required for testing Stripe integration without hitting real APIs. 3.26.1 is latest (Oct 2025). The standard for HTTP stubbing in Ruby. |
| vcr | ~> 6.4 | Record/replay HTTP interactions | Works with webmock to record real Stripe API responses once, replay in tests. 6.4.0 is latest (Dec 2025). Ensures tests are fast, deterministic, and reflect real API behavior. |

**Implementation notes:**
- VCR cassettes stored in `test/cassettes/`
- Configure VCR to hook into webmock, filter sensitive data (Stripe keys) from cassettes
- System tests (Capybara) already set up -- extend for MFA enrollment flows, billing flows
- Integration tests for API endpoints using standard ActionDispatch::IntegrationTest
- Stripe provides `stripe-mock` but VCR + webmock is simpler and more Ruby-idiomatic

**Confidence:** HIGH -- webmock + VCR is the standard combination for testing external API integrations in Ruby. Versions verified on RubyGems.

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| TOTP | rotp | devise-two-factor | We don't use Devise. devise-two-factor wraps rotp anyway. |
| TOTP | rotp | active_model_otp | Less maintained, smaller community. rotp is more direct. |
| TOTP | rotp | WebAuthn/passkeys | WebAuthn is more secure but requires hardware/platform support. TOTP is table stakes -- add WebAuthn later as an enhancement. |
| QR codes | rqrcode | google-qr | google-qr depends on Google's deprecated Chart API. rqrcode is pure Ruby. |
| Authorization | pundit | cancancan | CanCanCan's single Ability class becomes unwieldy. Pundit's per-model policies are cleaner. |
| Authorization | pundit | action_policy | action_policy is newer with fewer community examples. Pundit is battle-tested. More features than needed for this scope. |
| Billing | pay | stripe gem (direct) | Direct Stripe requires reimplementing webhook handling, customer sync, subscription lifecycle. Pay handles all of this. |
| Billing | pay | RailsBilling | Too new, less community adoption than Pay. |
| API auth | Custom | api_keys gem (v0.2.1) | Pre-1.0, brings unnecessary UI engine. API key auth is trivial to build. |
| API auth | Custom | doorkeeper (OAuth2) | Massive overkill for personal API keys. OAuth2 is for third-party app authorization. |
| API auth | Custom | jwt | JWT is stateless but not revocable without extra infrastructure. API keys stored in DB are simpler and revocable. |
| JSON | jbuilder (existing) | active_model_serializers | AMS is effectively unmaintained. Jbuilder is already in the Gemfile and is Rails default. |
| HTTP stubs | webmock + vcr | stripe-mock (Docker) | Adds Docker dependency to test suite. VCR cassettes are simpler and already work with Minitest. |

## What NOT to Add

| Gem/Technology | Why Avoid |
|----------------|-----------|
| devise | Already have custom auth. Adding Devise would require rewriting authentication entirely. |
| devise-two-factor | Depends on Devise. Use rotp directly. |
| doorkeeper | OAuth2 is overkill. Simple API keys suffice. |
| jwt | Stateless tokens add complexity without benefit for this use case. |
| rolify | Many-to-many user-role mapping is unnecessary. Single role enum suffices. |
| stripe (direct, without pay) | Rebuilds what Pay provides out of the box. |
| redis | Not needed. Solid Queue/Cache/Cable already use SQLite. |
| node/webpack/esbuild | Importmap handles JS. No build step needed for these features. |
| api_keys gem | Pre-1.0, unnecessary engine. Build it yourself in ~50 lines. |

## Installation

```bash
# Add production gems
bundle add rotp --version "~> 6.3"
bundle add rqrcode --version "~> 3.2"
bundle add pundit --version "~> 2.5"
bundle add pay --version "~> 11.4"

# Test-only gems (add to test group in Gemfile manually):
#   gem "webmock", "~> 3.26"
#   gem "vcr", "~> 6.4"

bundle install

# Generate Pay migrations and Pundit base policy
bin/rails pay:install:migrations
bin/rails generate pundit:install
bin/rails db:migrate
```

## New Gem Count

**Total new production gems:** 4 (rotp, rqrcode, pundit, pay)
**Total new test gems:** 2 (webmock, vcr)
**Total new gems:** 6

This is a minimal footprint. Each gem earns its place by solving a non-trivial problem that would be expensive to build from scratch (except API key auth, which we intentionally build ourselves).

## Integration Points with Existing Stack

| Existing | New Addition | Integration |
|----------|-------------|-------------|
| has_secure_password (bcrypt) | rotp (TOTP) | MFA adds a second factor after password verification. Session flow: password -> TOTP challenge -> authenticated. |
| User model (admin boolean) | Pundit (role enum) | Migrate `admin` boolean to `role` enum. Pundit policies replace `if current_user.admin?` checks. |
| User model (email_address) | Pay gem | **Must add** `alias_attribute :email, :email_address` for Pay compatibility. |
| Solid Queue | Pay webhooks | Stripe webhook events processed as background jobs via Solid Queue. No Redis needed. |
| Rack::Attack | API auth | API endpoints rate-limited by API key (not just IP). Add Rack::Attack throttle for `api_key` discriminator. |
| Turbo/Stimulus | MFA enrollment UI | QR code display and TOTP input use standard Turbo forms. Stimulus controller for clipboard copy of backup codes. |
| Kamal deployment | Stripe webhook URL | Configure webhook endpoint URL in Stripe dashboard pointing to production domain. No Kamal config changes. |
| Rails credentials | Stripe keys | Store `stripe.publishable_key`, `stripe.secret_key`, `stripe.webhook_signing_secret` in Rails credentials. |
| ActionMailer + letter_opener | Billing emails | Stripe handles transactional billing emails (receipts, upcoming invoice). App sends role-change notifications. |
| jbuilder | API responses | Already in Gemfile. Use for JSON API responses. No additional serialization gem needed. |

## Sources

- [rotp gem on RubyGems (v6.3.0)](https://rubygems.org/gems/rotp/versions/6.3.0) -- HIGH confidence
- [rotp on GitHub](https://github.com/mdp/rotp) -- HIGH confidence
- [rqrcode on RubyGems (v3.2.0)](https://rubygems.org/gems/rqrcode) -- HIGH confidence
- [Pundit on RubyGems (v2.5.2)](https://rubygems.org/gems/pundit) -- HIGH confidence
- [Pundit on GitHub](https://github.com/varvet/pundit) -- HIGH confidence
- [Pay gem on GitHub (v11.4.3)](https://github.com/pay-rails/pay) -- HIGH confidence
- [Pay gem on RubyGems](https://rubygems.org/gems/pay) -- HIGH confidence
- [api_keys gem on RubyGems (v0.2.1)](https://rubygems.org/gems/api_keys) -- evaluated and rejected
- [webmock on RubyGems (v3.26.1)](https://rubygems.org/gems/webmock) -- HIGH confidence
- [VCR on RubyGems (v6.4.0)](https://rubygems.org/gems/vcr) -- HIGH confidence
- [Stripe webhook best practices](https://docs.stripe.com/webhooks) -- HIGH confidence
- [Keygen blog: TOTP 2FA in Rails using ROTP](https://keygen.sh/blog/how-to-implement-totp-2fa-in-rails-using-rotp/) -- MEDIUM confidence
- [Keygen blog: API key auth in Rails](https://keygen.sh/blog/how-to-implement-api-key-authentication-in-rails-without-devise/) -- MEDIUM confidence
