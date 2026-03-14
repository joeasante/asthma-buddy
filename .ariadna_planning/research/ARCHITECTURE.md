# Architecture Research: SaaS Foundation Features

**Domain:** SaaS security/billing/API layer for health tracking app
**Researched:** 2026-03-14
**Overall confidence:** HIGH (existing codebase well-understood, patterns well-established in Rails ecosystem)

## Existing Architecture Snapshot

```
Browser --> ApplicationController (Authentication concern)
              |
              +--> Current.session --> Session model --> User model (has_secure_password)
              |
              +--> Admin::BaseController (admin? boolean guard)
              |
              +--> Resource controllers (all scoped to Current.user)
              |
              +--> Solid Queue (background jobs via SQLite)
```

**Key existing patterns:**
- `Authentication` concern on `ApplicationController` using signed cookie (`session_id`)
- `Current.session` / `Current.user` thread-local attributes
- `User#admin?` boolean column for admin access
- `Session` model tracks `user_agent`, `ip_address`, `created_at`
- `SessionsController#create` authenticates with `User.authenticate_by`, then calls `start_new_session_for`
- 60-minute idle timeout via `session[:last_seen_at]`
- Rate limiting on login (10 per 3 minutes)
- All resources scoped to `Current.user` (no multi-tenancy)
- SQLite WAL mode, `max_connections: 12`, `timeout: 5000`

## Integration Points

### 1. MFA (TOTP) Integration Points

**Touches existing code:**

| File | Change Type | What Changes |
|------|-------------|--------------|
| `SessionsController#create` | MODIFY | After password verification succeeds, check if user has MFA enabled. If yes, redirect to MFA challenge instead of completing login. |
| `Authentication` concern | MODIFY | Add `mfa_verified?` check. After MFA is enabled, a session is not fully authenticated until TOTP is verified. Add `require_mfa_verification` step. |
| `Session` model | MODIFY | Add `mfa_verified_at` datetime column. A session without this timestamp is "pending MFA". |
| `User` model | MODIFY | Add `has_many :totp_credentials` or add `otp_secret` column directly. Add `mfa_enabled?` convenience method. |
| `db/schema.rb` | MODIFY | New columns on `users` and/or `sessions` tables. |

**New code:**

| Component | Purpose |
|-----------|---------|
| `Mfa::TotpController` | Setup flow (generate secret, show QR, verify first code) and challenge flow (verify code during login) |
| `Mfa::RecoveryCodesController` | Generate, display, regenerate recovery codes |
| Migration: `add_otp_secret_to_users` | `otp_secret:string(encrypted)`, `otp_required_for_login:boolean` |
| Migration: `add_mfa_verified_at_to_sessions` | `mfa_verified_at:datetime` |
| Migration: `create_recovery_codes` | `recovery_codes` table (user_id, code_digest, used_at) |
| Views: MFA setup wizard | QR code display (rqrcode gem), code entry form |
| Views: MFA challenge | Code entry form shown during login |

**Data flow change:**

```
BEFORE:
  POST /session (email+password) --> authenticate_by --> start_new_session_for --> redirect to dashboard

AFTER (MFA enabled):
  POST /session (email+password) --> authenticate_by --> store user_id in session[:pending_mfa_user_id]
    --> redirect to /mfa/challenge
  POST /mfa/challenge (totp_code) --> verify TOTP --> start_new_session_for --> set mfa_verified_at
    --> redirect to dashboard

AFTER (MFA disabled):
  POST /session (email+password) --> authenticate_by --> start_new_session_for --> redirect to dashboard
  (unchanged)
```

### 2. RBAC Integration Points

**Touches existing code:**

| File | Change Type | What Changes |
|------|-------------|--------------|
| `User` model | MODIFY | Add `role` enum column (`:member`, `:clinician`, `:admin`). Remove or alias `admin?` to check `role == :admin`. |
| `Admin::BaseController` | MODIFY | Change `require_admin` to use role-based check instead of boolean. |
| `ApplicationController` | MODIFY | Add `authorize!` / policy helper methods. |
| All controllers with admin checks | MODIFY | Use policy/role checks instead of `Current.user&.admin?`. |
| Migration | NEW | `add_role_to_users` (integer enum, default: 0/member). Backfill existing `admin: true` users to admin role. Remove `admin` column in follow-up. |

**New code:**

| Component | Purpose |
|-----------|---------|
| `app/policies/` directory | Policy classes (one per resource) for authorization logic |
| `ApplicationPolicy` | Base policy class with sensible defaults |
| `Authorization` concern | `authorize(record)`, `policy(record)` helpers mixed into ApplicationController |
| Per-resource policies | `SymptomLogPolicy`, `MedicationPolicy`, `UserPolicy`, etc. |

**Pattern recommendation:** Use Pundit. It is lightweight (no DSL magic), works with any auth system (no Devise dependency), and maps 1:1 to controller actions. The existing `admin?` boolean maps cleanly to a role enum.

**Migration strategy for admin boolean to role enum:**
1. Add `role` integer column with default `0` (member)
2. Backfill: `UPDATE users SET role = 2 WHERE admin = true`
3. Add `User#admin?` alias: `def admin? = role_admin?`
4. All existing `admin?` checks continue working
5. Later: remove `admin` boolean column

### 3. Stripe Subscription Billing Integration Points

**Touches existing code:**

| File | Change Type | What Changes |
|------|-------------|--------------|
| `User` model | MODIFY | Add `pay_customer` declaration. User must respond to `email` (it has `email_address` -- needs alias or custom method). |
| `Gemfile` | MODIFY | Add `pay ~> 11.4`, `stripe` gems. |
| `ApplicationController` | MODIFY | Add subscription status checks for feature gating. |
| `config/routes.rb` | MODIFY | Pay mounts webhook endpoint automatically. Add billing/subscription routes. |
| `config/credentials.yml.enc` | MODIFY | Add Stripe API keys and webhook signing secret. |

**Critical compatibility note:** The `User` model uses `email_address` not `email`. Pay gem expects `email`. Solutions:
1. Add `alias_attribute :email, :email_address` to User model, OR
2. Define `def email = email_address` on User model
Option 1 is cleaner.

**New code:**

| Component | Purpose |
|-----------|---------|
| Pay migrations (4 tables) | `pay_customers`, `pay_subscriptions`, `pay_charges`, `pay_payment_methods` |
| `Billing::SubscriptionsController` | Manage subscription lifecycle (create checkout session, portal, cancel) |
| `Billing::WebhooksController` | Pay handles this automatically via mounted engine |
| `Subscribable` concern | Feature-gating helpers: `current_plan`, `can_access?(:feature)`, `subscription_active?` |
| Plan configuration | `config/plans.yml` or similar defining plan tiers and feature sets |
| Stripe webhook job | Pay processes webhooks via Active Job (uses Solid Queue automatically) |
| Views: pricing page | Plan comparison, checkout buttons |
| Views: billing settings | Current plan, payment method, invoices, cancel |

**Pay gem tables created:**

| Table | Key Columns | Purpose |
|-------|-------------|---------|
| `pay_customers` | `owner_type`, `owner_id`, `processor`, `processor_id` | Links User to Stripe Customer |
| `pay_subscriptions` | `customer_id`, `processor_id`, `name`, `status`, `current_period_end` | Tracks subscription state |
| `pay_charges` | `customer_id`, `processor_id`, `amount`, `currency` | Payment history |
| `pay_payment_methods` | `customer_id`, `processor_id`, `type` | Stored cards/payment methods |

### 4. REST API with API Key Auth Integration Points

**Touches existing code:**

| File | Change Type | What Changes |
|------|-------------|--------------|
| `Authentication` concern | MODIFY | Add API token authentication path alongside cookie auth. `resume_session` should try cookie first, then fall back to API key bearer token. |
| `ApplicationController` | MODIFY | Set `Current.user` from API key's owner when authenticating via token. |
| `config/routes.rb` | MODIFY | Add `namespace :api, defaults: { format: :json } do ... end` with versioned routes. |

**New code:**

| Component | Purpose |
|-----------|---------|
| `ApiKey` model | `token_digest`, `user_id`, `name`, `last_used_at`, `expires_at`, `revoked_at` |
| `Api::BaseController` | Inherits ApplicationController, skips CSRF, authenticates via Bearer token |
| `Api::V1::` controllers | Versioned API endpoints for health data resources |
| `ApiAuthentication` concern | `authenticate_with_http_token` + API key lookup by digest |
| `Settings::ApiKeysController` | CRUD for API keys in the web UI |
| Migration: `create_api_keys` | `api_keys` table |
| Rate limiting config | Per-API-key rate limiting via Rack::Attack |

**API key security pattern:**
- Generate random token with `SecureRandom.hex(32)`
- Store only `Digest::SHA256.hexdigest(token)` in database
- Show raw token to user exactly once at creation time
- Lookup: hash incoming bearer token, find by digest
- Never log raw tokens

**Authentication flow:**

```
API Request with "Authorization: Bearer <token>"
  --> ApiAuthentication concern
    --> authenticate_with_http_token
      --> hash token, find ApiKey by token_digest
        --> set Current.session = nil, Current.user = api_key.user
          --> update api_key.last_used_at
            --> proceed to controller action
```

**Current.user compatibility:** The API auth sets `Current.user` directly (bypassing `Current.session`). All existing authorization code that uses `Current.user` works without changes. Controllers that specifically need `Current.session` (e.g., for session timeout) skip that for API requests.

### 5. Integration Tests

**Touches existing code:**

| File | Change Type | What Changes |
|------|-------------|--------------|
| `test/test_helper.rb` | MODIFY | Add API test helpers, Stripe mock helpers, MFA test helpers |
| `test/test_helpers/session_test_helper.rb` | MODIFY | Add `sign_in_with_mfa_as(user)` helper |
| `test/fixtures/` | MODIFY | Add fixtures for new models (api_keys, recovery_codes, pay tables) |

**New code:**

| Component | Purpose |
|-----------|---------|
| `test/test_helpers/api_test_helper.rb` | `api_sign_in_as(user)` sets Bearer token header |
| `test/test_helpers/stripe_test_helper.rb` | Stripe mock setup, webhook event factories |
| `test/integration/api/` | API endpoint integration tests |
| `test/integration/billing/` | Subscription lifecycle tests |
| `test/integration/mfa/` | MFA setup and challenge flow tests |
| `test/controllers/api/v1/` | API controller tests |

## New Components (Full List)

### Models

| Model | Table | Key Relationships |
|-------|-------|-------------------|
| `ApiKey` | `api_keys` | `belongs_to :user` |
| `RecoveryCode` | `recovery_codes` | `belongs_to :user` |
| Pay::Customer | `pay_customers` | Polymorphic to User |
| Pay::Subscription | `pay_subscriptions` | `belongs_to :customer` |
| Pay::Charge | `pay_charges` | `belongs_to :customer` |
| Pay::PaymentMethod | `pay_payment_methods` | `belongs_to :customer` |

### Controllers

| Controller | Namespace | Purpose |
|------------|-----------|---------|
| `Mfa::TotpController` | root | TOTP setup + login challenge |
| `Mfa::RecoveryCodesController` | root | Recovery code management |
| `Billing::SubscriptionsController` | root | Subscription management UI |
| `Billing::CheckoutsController` | root | Stripe Checkout session creation |
| `Settings::ApiKeysController` | settings | API key CRUD in web UI |
| `Api::BaseController` | api | Base for all API controllers |
| `Api::V1::SymptomLogsController` | api/v1 | API for symptom logs |
| `Api::V1::PeakFlowReadingsController` | api/v1 | API for peak flow readings |
| `Api::V1::MedicationsController` | api/v1 | API for medications |
| `Api::V1::DoseLogsController` | api/v1 | API for dose logs |
| `Api::V1::HealthEventsController` | api/v1 | API for health events |

### Concerns

| Concern | Mixed Into | Purpose |
|---------|-----------|---------|
| `ApiAuthentication` | `Api::BaseController` | Bearer token auth |
| `Authorization` | `ApplicationController` | Pundit integration |
| `Subscribable` | `ApplicationController` | Subscription feature gating |

## Modified Components (Full List)

| Component | Modification |
|-----------|-------------|
| `User` model | Add `role` enum, `pay_customer`, `otp_secret`, `otp_required_for_login`, `has_many :api_keys`, `has_many :recovery_codes`, `alias_attribute :email, :email_address` |
| `Session` model | Add `mfa_verified_at` column |
| `SessionsController#create` | MFA challenge redirect for MFA-enabled users |
| `Authentication` concern | API key fallback auth path, MFA verification check |
| `ApplicationController` | Authorization helpers, subscription gating |
| `Admin::BaseController` | Role-based check instead of boolean |
| `config/routes.rb` | API namespace, MFA routes, billing routes, API key settings |
| `Gemfile` | Add `pay`, `stripe`, `rotp`, `rqrcode`, `pundit` |
| `config/credentials.yml.enc` | Stripe keys, webhook secret |
| `test/test_helper.rb` | New test helpers |

## Data Flow Changes

### Authentication Flow (Modified)

```
                          +------------------+
                          | Request arrives  |
                          +--------+---------+
                                   |
                          +--------v---------+
                          | Has Bearer token?|
                          +--------+---------+
                            YES /      \ NO
                               /        \
                    +---------v--+   +---v-----------+
                    | API Key    |   | Has session   |
                    | auth flow  |   | cookie?       |
                    +-----+------+   +-------+-------+
                          |            YES /     \ NO
                          |               /       \
                    +-----v------+  +----v----+  +--v-----------+
                    | Set        |  | Resume  |  | 401 / login  |
                    | Current.   |  | session |  | redirect     |
                    | user from  |  +----+----+  +--------------+
                    | api_key    |       |
                    +-----+------+  +----v-----------+
                          |         | MFA required   |
                          |         | & not verified?|
                          |         +----+-----------+
                          |          YES /     \ NO
                          |             /       \
                          |    +-------v---+  +-v-----------+
                          |    | MFA       |  | Fully       |
                          |    | challenge |  | authenticated|
                          |    +-----------+  +-------------+
                          |                        |
                          +----------+-------------+
                                     |
                              +------v------+
                              | Authorize   |
                              | via Pundit  |
                              +------+------+
                                     |
                              +------v------+
                              | Check       |
                              | subscription|
                              | (if gated)  |
                              +------+------+
                                     |
                              +------v------+
                              | Controller  |
                              | action      |
                              +-------------+
```

### Webhook Data Flow (New)

```
Stripe --> POST /pay/webhooks/stripe
  --> Pay::Webhooks::StripeController (mounted by Pay engine)
    --> Verify Stripe signature
      --> Process event (subscription.updated, charge.succeeded, etc.)
        --> Update Pay::Subscription / Pay::Charge records
          --> Trigger Pay callbacks (if configured)
            --> Solid Queue job for heavy processing
```

## SQLite-Specific Considerations

### WAL Mode and Concurrent Writes

The app already uses WAL mode with `timeout: 5000`. This is critical because:

1. **Webhook processing** -- Stripe webhooks arrive asynchronously and write to Pay tables. WAL mode allows concurrent reads while a write is in progress, preventing webhook processing from blocking web requests.

2. **API requests** -- API clients may fire concurrent requests. SQLite's single-writer limitation means writes serialize, but with WAL mode and the 5000ms timeout, this is acceptable for the expected traffic volume (single-user health app, not high-concurrency SaaS).

3. **Solid Queue** -- Background jobs already write to the queue database concurrently. The existing 4-database production split (primary, cache, queue, cable) means queue writes don't contend with primary data writes.

### Pay Gem + SQLite

Pay stores its tables in the primary database. No additional database configuration needed. Pay's migrations use standard ActiveRecord and work with SQLite. The `pay_customers`, `pay_subscriptions`, `pay_charges`, `pay_payment_methods` tables all use standard column types.

### Encrypted Columns

The `otp_secret` on the User model should use Rails 8's built-in `encrypts` attribute encryption (Active Record Encryption). This stores the encrypted value in a standard string column and works with SQLite without any special configuration. Requires `config/credentials.yml.enc` to contain encryption keys (Rails generates these by default).

```ruby
class User < ApplicationRecord
  encrypts :otp_secret, deterministic: false
end
```

## Build Order

The features have clear dependencies that dictate build order:

### Phase 1: RBAC (Foundation -- No External Dependencies)

**Why first:** Every subsequent feature needs role-based authorization. MFA setup needs "who can require MFA for others?" Billing needs "what can each role access?" API needs "what data can each role read/write?"

**Dependencies:** None. Pure internal refactor.
**Risk:** Low. The existing `admin?` boolean maps directly to a role enum.

**Steps:**
1. Add `role` enum column to users, backfill from `admin` boolean
2. Add Pundit gem, create `ApplicationPolicy`
3. Create per-resource policies
4. Mix `Authorization` concern into `ApplicationController`
5. Update `Admin::BaseController` to use role check
6. Write policy tests
7. Remove `admin` boolean column (cleanup)

### Phase 2: MFA/TOTP (Security -- Modifies Auth Flow)

**Why second:** Must happen before API keys exist (API keys are a secondary auth path that could bypass MFA if not designed carefully). MFA hardens the auth system that everything else depends on.

**Dependencies:** RBAC (admin can enforce MFA for all users).
**Risk:** Medium. Modifies the critical authentication flow. Must not break existing sessions.

**Steps:**
1. Add `otp_secret`, `otp_required_for_login` to users
2. Add `mfa_verified_at` to sessions
3. Create TOTP setup flow (generate secret, QR, verify)
4. Create recovery codes model and flow
5. Modify `SessionsController#create` for MFA challenge
6. Modify `Authentication` concern for MFA verification
7. Write integration tests for full MFA login flow

### Phase 3: REST API with API Key Auth (External Interface)

**Why third:** Needs RBAC for authorization policies. Should come after MFA so API key model can be designed with proper security (API keys bypass MFA by design -- they are a separate auth path).

**Dependencies:** RBAC (policies apply to API actions), MFA (design decision: API keys bypass MFA).
**Risk:** Medium. New attack surface. Must ensure API auth sets `Current.user` correctly so all existing authorization works.

**Steps:**
1. Create `ApiKey` model with token digest
2. Create `ApiAuthentication` concern
3. Create `Api::BaseController`
4. Create versioned API controllers (V1)
5. Add API key management UI in settings
6. Add per-API-key rate limiting
7. Write API integration tests

### Phase 4: Stripe Subscription Billing (External Service)

**Why last:** Most complex, most external dependencies, and benefits from having RBAC (plan-based feature gating), MFA (secure billing changes), and API (webhook processing patterns) already in place.

**Dependencies:** RBAC (plan tiers map to role capabilities), API patterns (webhook processing).
**Risk:** High. External service dependency, webhook reliability, payment edge cases, UK GDPR implications for billing data alongside health data.

**Steps:**
1. Add Pay gem, run migrations
2. Configure Stripe credentials
3. Define plan tiers in configuration
4. Create checkout and subscription management controllers
5. Add `Subscribable` concern for feature gating
6. Wire up webhook processing
7. Create billing UI (pricing page, billing settings)
8. Write integration tests with Stripe mocks

### Phase 5: Integration Tests (Cross-Cutting)

**Why throughout and at end:** Each phase includes its own tests, but cross-feature integration tests (e.g., "admin with MFA uses API to check billing status") come last when all features exist.

**Dependencies:** All features complete.

## Anti-Patterns to Avoid

### Anti-Pattern: Overloading Current.session for API Requests
**Why bad:** API requests have no session. Setting `Current.session` to a fake object breaks session-specific logic (timeout, MFA verification).
**Instead:** Set `Current.user` directly for API requests. Make session-dependent code (`check_session_freshness`, MFA verification) skip API requests.

### Anti-Pattern: Storing OTP Secret in Plain Text
**Why bad:** If database is compromised, attacker can generate valid TOTP codes.
**Instead:** Use `encrypts :otp_secret` (Rails Active Record Encryption).

### Anti-Pattern: Storing API Keys in Plain Text
**Why bad:** Database compromise exposes all API keys.
**Instead:** Store `Digest::SHA256.hexdigest(token)`. Show raw token once at creation.

### Anti-Pattern: Synchronous Webhook Processing
**Why bad:** Stripe expects < 10 second response. Heavy processing blocks the response.
**Instead:** Pay gem already processes webhooks via Active Job. Solid Queue handles this.

### Anti-Pattern: Using Pay's Default Webhook Endpoint Without Authentication
**Why bad:** Anyone can POST fake events to your webhook endpoint.
**Instead:** Pay verifies Stripe webhook signatures automatically. Ensure `STRIPE_SIGNING_SECRET` is configured.

### Anti-Pattern: Feature Gating in Views Only
**Why bad:** Users can still access features via direct URL or API.
**Instead:** Gate features in controller `before_action` callbacks AND in Pundit policies. Views are cosmetic.

## Sources

- [ROTP gem (v6.3.0)](https://github.com/mdp/rotp) -- HIGH confidence, official repo
- [Pay gem (v11.4.0)](https://github.com/pay-rails/pay) -- HIGH confidence, official repo
- [Keygen TOTP tutorial](https://keygen.sh/blog/how-to-implement-totp-2fa-in-rails-using-rotp/) -- MEDIUM confidence
- [Rails ActionController::HttpAuthentication::Token](https://api.rubyonrails.org/classes/ActionController/HttpAuthentication/Token.html) -- HIGH confidence, official docs
- [Stripe webhook signature docs](https://docs.stripe.com/webhooks/signature) -- HIGH confidence, official docs
- [Pay gem webhooks docs](https://github.com/pay-rails/pay/blob/main/docs/7_webhooks.md) -- HIGH confidence, official docs
- Existing codebase analysis -- HIGH confidence, direct inspection
