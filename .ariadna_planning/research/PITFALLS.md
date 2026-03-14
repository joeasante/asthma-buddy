# Pitfalls Research

**Domain:** SaaS foundation features (MFA, RBAC, Stripe billing, REST API) added to existing Rails 8.1.2 health tracking app
**Researched:** 2026-03-14
**Overall confidence:** HIGH (verified against current codebase structure, official SQLite/Rails/Stripe documentation, and multiple independent sources)

**Codebase context used:** `Authentication` concern (cookie-based session via `cookies.signed[:session_id]`), `User` model (`has_secure_password`, boolean `admin` column added 2026-03-13), `Admin::BaseController` (`Current.user&.admin?` guard), `database.yml` (WAL mode, 5000ms timeout, 4 separate SQLite databases), `SessionsController` (rate-limited, `start_new_session_for` called on password success).

---

## Critical Pitfalls

These cause security vulnerabilities, health data breaches, or require rewrites.

### Pitfall 1: MFA Half-Authenticated Session Bypass (Session Puzzling)

**What goes wrong:** After a user enters correct email/password but before entering their TOTP code, the app creates a session cookie via `start_new_session_for` (line 39 of `sessions_controller.rb`). The user is technically "authenticated" during the gap between password verification and TOTP entry. Every endpoint checking `authenticated?` or `Current.user` passes, because `resume_session` finds a valid session cookie.

**Why it happens:** The current `Authentication` concern resumes sessions from `cookies.signed[:session_id]`. If `start_new_session_for` fires before TOTP verification, all `before_action :require_authentication` checks pass. This is the "Session Puzzling" vulnerability -- the session is valid across the entire app despite MFA being incomplete. The `check_session_freshness` callback in `ApplicationController` checks inactivity timeout but has no concept of MFA completion state.

**Consequences:** An attacker with stolen credentials bypasses MFA entirely. They access health data (UK GDPR special category), change settings, or retrieve MFA backup codes from the intermediate state. For an app handling health data under UK GDPR Article 9, this is a reportable breach to the ICO.

**Prevention:**
- Do NOT call `start_new_session_for` until TOTP is verified. After password verification, store only `session[:pending_user_id]` (Rails session, not the app's Session model) with a 5-minute expiry check.
- Add `mfa_verified_at` timestamp to the `sessions` table. Add `before_action :require_mfa_completion` to `ApplicationController` that redirects to the TOTP entry page when the user has MFA enabled but the current session lacks `mfa_verified_at`.
- The intermediate state (password OK, MFA pending) must have access to exactly ONE endpoint: the TOTP verification form. All other routes redirect to it.

**Detection:** Log in with valid credentials, then immediately navigate to `/dashboard` before entering TOTP. If it loads, the vulnerability exists.

**Phase:** MFA implementation. Non-negotiable first design decision.

**Source:** [Session Puzzling to Bypass Two-Factor Authentication](https://www.invicti.com/blog/web-security/two-interesting-session-related-vulnerabilities) (HIGH confidence -- describes exact attack vector)

---

### Pitfall 2: SQLite BUSY Exceptions from Stripe Webhook Bursts

**What goes wrong:** Stripe sends webhook events in rapid bursts. A single checkout triggers `checkout.session.completed`, `invoice.created`, `invoice.paid`, and `customer.subscription.created` within seconds. Each webhook handler writes to the database. SQLite allows only one writer at a time. If Puma is handling a user request that writes (dose log, symptom entry) simultaneously with webhook processing, the second writer waits up to `timeout: 5000` ms. Stripe has a 20-second timeout for webhook responses. If 4-5 webhooks queue behind each other plus regular app writes, later webhooks timeout. Stripe retries, creating MORE concurrent writes.

**Why it happens:** Even with WAL mode and IMMEDIATE transactions (Rails 8 defaults), SQLite serializes all writes through a single lock. The `busy_timeout` of 5000ms is the retry window, not a guarantee. Under burst conditions, cumulative wait exceeds Stripe's patience.

**Consequences:** Stripe marks the webhook endpoint as unhealthy after repeated timeouts. Subscription state drifts -- customers are charged but the app does not reflect it. Or duplicate processing occurs if idempotency is not handled.

**Prevention:**
- Process webhooks asynchronously. The webhook controller should ONLY: (1) verify the Stripe signature, (2) INSERT the raw event payload into a `stripe_events` table with a unique constraint on `stripe_event_id`, (3) enqueue a Solid Queue job, (4) return `200 OK`. Total DB write time: one fast INSERT.
- The Solid Queue job processes events sequentially from the `stripe_events` table. No burst contention.
- This is particularly important because the app runs on a single Hetzner VPS -- there is no horizontal scaling to absorb bursts.

**Detection:** Use `stripe trigger checkout.session.completed` 5 times in rapid succession while simultaneously running a test that writes to the database. Monitor for `BusyException` in logs.

**Phase:** Billing phase. Must be the architectural foundation of webhook handling, not retrofitted.

**Source:** [SQLite on Rails -- Improving Concurrency](https://fractaledmind.com/2023/12/11/sqlite-on-rails-improving-concurrency/) (HIGH confidence), [SQLite Concurrent Writes and Database Locked Errors](https://tenthousandmeters.com/blog/sqlite-concurrent-writes-and-database-is-locked-errors/) (HIGH confidence)

---

### Pitfall 3: API Keys Bypass MFA Requirement

**What goes wrong:** API key authentication for the REST API authenticates directly to a user without any MFA check. An attacker who obtains an API key has full access to health data, even if the user has MFA enabled. The two auth paths (session + API key) create an asymmetric security model where MFA only protects the browser path.

**Why it happens:** The `Authentication` concern has a single path: cookie-based session lookup. Adding API key auth means a second path that sets `Current.user` without going through session/MFA flow. MFA checks live on sessions; API keys exist outside sessions.

**Consequences:** API keys become the weakest link. For UK GDPR special category health data, the app's security posture is only as strong as API key storage -- no second factor. The ICO could view this as insufficient technical measures under Article 32.

**Prevention:**
- API keys must have explicit scopes: `read`, `write`, `admin`. Default to `read` only.
- Require MFA completion in the current browser session before an API key can be generated. This ensures the key creator proved identity via MFA.
- API keys should NOT access data export or bulk-read endpoints. Health data bulk access is session-only, with MFA verified.
- Rate-limit API endpoints more aggressively than web endpoints. Per-key limits, not just per-IP.
- Treat API keys as equivalent to long-lived passwords in the security documentation and DPIA.

**Detection:** Create an API key for a user with MFA enabled. Use the key to `GET /api/v1/symptom_logs`. If it returns data without any MFA interaction, the asymmetry exists.

**Phase:** API authentication phase. API auth concern must be MFA-aware from day one.

---

### Pitfall 4: RBAC Migration Creates Dual Source of Truth for Admin

**What goes wrong:** The app has a boolean `admin` column (added 2026-03-13) checked in `Admin::BaseController#require_admin`, `Admin::UsersController#toggle_admin`, and JSON serialization in `Admin::UsersController#index`. Introducing RBAC with a `role` column creates two sources of truth. During migration, `toggle_admin` sets the boolean without updating the role, or vice versa. A non-admin gains admin access to Mission Control Jobs.

**Why it happens:** The boolean `admin` field is referenced in at least 3 controller files and 1 migration. Adding a `role` enum column without deprecating the boolean means code paths diverge. Some check `user.admin?` (boolean), others check `user.role == 'admin'` (enum). They can disagree.

**Consequences:** Privilege escalation -- a user with `admin: false` but `role: :admin` (or vice versa) gets inconsistent access. The `toggle_admin` action becomes particularly dangerous: it flips the boolean but not the role, creating a user who appears admin in one check and non-admin in another.

**Prevention:**
1. Add `role` enum column. Migration maps `admin: true` to `role: :admin`, `admin: false` to `role: :user`.
2. Override `admin?` to delegate to `role == :admin`. This preserves backward compatibility while all code paths still work. All existing checks pass without modification.
3. Update `toggle_admin` to set the role, not the boolean. Or better: replace it with a proper role-assignment action.
4. Remove the `admin` column only after all references are updated and the full test suite (576 tests) passes.
5. Add a regression test: `assert_equal User.where(admin: true).count, User.where(role: :admin).count`.

**Detection:** `grep -rn "\.admin" app/ config/ test/ --include="*.rb" --include="*.erb"` to find every reference. Each needs updating.

**Phase:** First step of RBAC phase. Must complete before adding any new roles.

---

## Integration Pitfalls

Mistakes caused by the interaction between features.

### Pitfall 5: Dual Auth Path Divergence Causes Session Policy Bypass

**What goes wrong:** The app needs to handle both Turbo/HTML (session auth) and JSON/API (API key auth). If API key auth is added to the `Authentication` concern as a fallback (e.g., "check cookie first, then check Authorization header"), a browser request with an expired session cookie but a valid API key in a header authenticates via the API path, bypassing `check_session_freshness` (the 60-minute idle timeout). Conversely, an API request with a stale session cookie gets a 302 redirect to the login page instead of a 401 JSON response.

**Why it happens:** `resume_session` returns the current session from a cookie. Adding `|| find_user_by_api_key` to this method mixes two auth paradigms. Session-only policies (MFA check, idle timeout, `last_seen_at` tracking) do not apply to API key auth, and API-only policies (scope checking, per-key rate limits) do not apply to sessions.

**Consequences:** Security policies are silently bypassed depending on which auth path wins. The 60-minute idle timeout -- a key security measure for health data -- becomes optional.

**Prevention:**
- Physically separate auth paths via controller namespaces. `Api::V1::BaseController < ActionController::API` uses ONLY `Authorization` header-based auth. No cookie lookup, no CSRF, no session idle timeout.
- Web controllers (`ApplicationController` subclasses) use ONLY cookie/session auth. No API key fallback.
- The existing `format.json` responses in `SessionsController` are for Turbo/fetch and stay on cookie auth. They are NOT the API.
- Shared business logic lives in model methods or service objects, never in controllers.

**Detection:** Send a request to a web endpoint with both a valid session cookie AND a valid API key header. Observe which auth path wins. If the API key path wins, session policies are bypassed.

**Phase:** API phase. Namespace separation is the first architectural decision.

---

### Pitfall 6: Stripe Metadata Leaks Health Data Context

**What goes wrong:** When creating Stripe customers or products, developers store metadata like `{ app: "asthma-buddy", user_email: "patient@example.com" }` or create products named "Asthma Management Premium." This metadata is visible in the Stripe Dashboard, in webhook payloads, in invoice PDFs, and to anyone with Stripe API access. The word "asthma" in billing context reveals a health condition.

**Why it happens:** Stripe encourages metadata for operational convenience. It is natural to include the app name. But for a health-specific app, the app name IS the health condition.

**Consequences:** The Stripe Dashboard becomes a store of UK GDPR Article 9 special category data. Stripe's Data Processing Agreement covers payment data processing under Article 6(1)(b) (contractual necessity), NOT health data under Article 9. You may need an explicit Article 9(2)(a) consent basis for this processing, and Stripe's standard DPA does not cover it. The ICO could view this as unlawful processing of special category data.

**Prevention:**
- Store only opaque identifiers in Stripe metadata: `{ user_id: "uuid-here" }`. No email, no name, no product name that reveals health conditions.
- Stripe product names must be generic: "Basic Plan", "Pro Plan" -- not "Asthma Buddy Basic" or "Health Tracking Premium."
- Invoice descriptions visible to patients should read "Subscription Service" not "Asthma Management Subscription."
- Document this policy in the DPIA. The billing system processes payment data only; health data stays in the app database.

**Detection:** After creating test subscriptions, search the Stripe Dashboard for "asthma", "health", "medication", or any user email. None should appear.

**Phase:** Billing phase. Establish as a policy BEFORE any Stripe integration code. First item in the Stripe setup checklist.

**Source:** [Stripe Privacy Center](https://stripe.com/legal/privacy-center) (HIGH confidence), [Stripe Data Processing Agreement](https://stripe.com/legal/dpa) (HIGH confidence)

---

### Pitfall 7: RBAC Scope Leaks in API Responses

**What goes wrong:** The REST API serves user-scoped health data. If RBAC adds roles that might see multiple users' data in the future (e.g., a clinician role), and API authorization is per-controller rather than per-query, a misconfigured endpoint returns unscoped data. Even without a clinician role, a missing `where(user: current_user)` clause on an API endpoint returns ALL users' records.

**Why it happens:** The current app scopes everything implicitly via `Current.user.symptom_logs`. The API might use `SymptomLog.find(params[:id])` instead of `Current.user.symptom_logs.find(params[:id])`, allowing IDOR (Insecure Direct Object Reference) attacks where one user accesses another's records by guessing IDs.

**Consequences:** Health data breach. One user sees another user's symptom logs, medications, or peak flow readings. Reportable under UK GDPR. SQLite integer auto-increment IDs are sequential and trivially guessable, making IDOR exploitation easy.

**Prevention:**
- Every API query MUST scope through the authenticated user's associations: `current_user.symptom_logs.find(params[:id])`, never `SymptomLog.find(params[:id])`.
- Use Pundit-style policy scoping where `policy_scope(SymptomLog)` automatically applies user scoping.
- Write IDOR tests for every API endpoint: authenticate as User A, attempt to access User B's resources by ID. Must return 404 (not 403 -- do not confirm the resource exists).
- For solo-developer context: do NOT build multi-user access (clinician sees patients) until there is a real requirement. YAGNI applies strongly here.

**Detection:** Create two users with data. Authenticate as User A via API key, request User B's symptom log by ID.

**Phase:** API phase. Scoping pattern must be established on the very first endpoint and tested on every subsequent one.

---

## SQLite-Specific Pitfalls

### Pitfall 8: Webhook Idempotency Race Condition with Check-Then-Insert

**What goes wrong:** You use a unique index on `stripe_event_id` for idempotency. Two identical webhook deliveries arrive simultaneously. Both run `StripeEvent.exists?(stripe_event_id: id)` -- both return `false` because neither has committed. Both INSERT. One succeeds, one raises `ActiveRecord::RecordNotUnique`. If uncaught, the webhook returns 500 and Stripe retries, amplifying the problem.

**Why it happens:** Even with IMMEDIATE transaction mode (where the second writer waits for the first), the `exists?` check and the INSERT must be in the same transaction for the check to be reliable. If the check runs before the transaction begins, or in a separate transaction, the race exists.

**Prevention:**
- Use atomic insert: `StripeEvent.insert({ stripe_event_id: id, payload: raw_body }, unique_by: :stripe_event_id)`. Rails `insert` method returns 0 rows affected if the unique constraint fires -- no exception, no race.
- As a belt-and-suspenders measure, rescue `ActiveRecord::RecordNotUnique` in the webhook controller and return `200 OK` (the event was already stored).
- The `busy_timeout: 5000` in `database.yml` ensures the second writer waits rather than failing immediately.

**Detection:** Send the same Stripe event ID twice with 0ms delay. Both should return 200. Only one `StripeEvent` record should exist in the database.

**Phase:** Billing phase. This is the very first piece of code in the webhook handler.

**Source:** [Rails PR #50371: IMMEDIATE transactions](https://github.com/rails/rails/pull/50371) (HIGH confidence), [Stripe Idempotent Requests](https://docs.stripe.com/api/idempotent_requests) (HIGH confidence)

---

### Pitfall 9: Database Split Collapse Causes Cross-Feature Contention

**What goes wrong:** The app uses 4 separate SQLite databases (primary, cache, queue, cable). Someone collapses them into one database "for simplicity" or "easier backups." Now Solid Queue polling, Solid Cache writes, Action Cable broadcasts, Stripe webhook processing, AND regular user requests all compete for a single write lock.

**Why it happens:** The 4-database split looks like over-engineering. A developer unfamiliar with the rationale consolidates them during a "simplification" refactor.

**Consequences:** Write contention increases dramatically. Solid Queue polls every few seconds (write to claim jobs). Solid Cache writes on every cache miss. Combined with webhook bursts and user activity, `BUSY` exceptions become frequent. The app becomes unreliable under even moderate load.

**Prevention:**
- Document WHY the 4-database split exists in a code comment in `database.yml` (it partially exists already -- "Store production database in the storage/ directory").
- Add a more explicit comment: "These databases are separate to avoid write lock contention between application data, cache, background jobs, and websockets. Do not consolidate."
- The `StripeEvent` model should live in the PRIMARY database (health/billing data), not the queue database.

**Detection:** Check `database.yml` has 4 databases in production. Verify `StripeEvent` model does not specify a different database connection.

**Phase:** Infrastructure awareness throughout all phases. Add the documentation comment in the first phase.

---

### Pitfall 10: Sequential Integer IDs Enable API Enumeration

**What goes wrong:** SQLite uses auto-increment integer primary keys by default. API endpoints expose these IDs (e.g., `/api/v1/symptom_logs/42`). An attacker increments the ID to enumerate all records, discovering total record counts or (if scoping is missing per Pitfall 7) accessing other users' data.

**Why it happens:** Rails default is integer PKs. Most Rails tutorials use them. The risk is higher for health data where even knowing a record EXISTS is sensitive information.

**Consequences:** Information disclosure (total number of symptom logs reveals usage patterns). Combined with missing scoping (Pitfall 7), full data breach.

**Prevention:**
- Scope every API query through the user's associations (primary defense -- see Pitfall 7). A scoped `find` returns 404 for IDs belonging to other users, preventing enumeration.
- Optionally, use UUIDs for API-facing resources. This is a bigger migration but eliminates enumeration entirely.
- At minimum, return 404 (not 403) when a scoped lookup fails, to avoid confirming resource existence.

**Phase:** API phase. The scoping pattern handles this. UUID migration is optional and can be deferred.

---

## Health Data + Billing Pitfalls

### Pitfall 11: No Data Deletion Path for Billing-Linked Users

**What goes wrong:** UK GDPR gives users the right to erasure (Article 17). The app must delete a user's health data on request. But if the user has an active Stripe subscription, deleting their account creates: orphaned Stripe customers, failed renewal charges with no user to map back to, and potential PCI data retention violations.

**Why it happens:** Account deletion is implemented for the app database only. The Stripe customer remains active. Or the Stripe customer is deleted but the subscription is still active, causing Stripe to attempt charges on a deleted customer with a valid payment method.

**Consequences:** GDPR non-compliance (data not actually deleted from Stripe). Orphaned charges generate disputes/chargebacks. Financial records required for UK tax law (6 years) conflict with erasure right.

**Prevention:**
- Account deletion flow: (1) Cancel all Stripe subscriptions via API, (2) Wait for `customer.subscription.deleted` webhook confirmation, (3) Delete Stripe customer via API, (4) Anonymise billing records needed for tax (keep amount/date, remove PII), (5) Delete app user record and all health data.
- Implement as a Solid Queue job with a "scheduled for deletion" state. Do not delete synchronously -- the Stripe API calls need error handling and retries.
- Store only the Stripe customer ID on the user record. When the user is deleted, this ID is all you need to clean up Stripe.

**Detection:** Delete a test user with an active subscription. Check Stripe Dashboard for the customer. Check for attempted charges in the following days.

**Phase:** Billing phase. Must be designed when subscriptions are implemented. Cannot be bolted on later.

---

### Pitfall 12: Billing Status Combined with Health Data in Responses

**What goes wrong:** A user's subscription status (active, cancelled, past_due) is included in the same API response or page context as their health data. If billing status is accessible with weaker controls than health data, or if billing + health data together enables health condition inference by Stripe support staff reviewing billing disputes, the data protection model breaks.

**Why it happens:** Developers treat billing as "less sensitive" than health data. But for a health-specific app, the combination of "this person pays for an asthma app" + "their subscription was cancelled" + dispute context could reveal health information to Stripe employees reviewing the dispute.

**Prevention:**
- Billing endpoints and health data endpoints must be separate -- never mix billing status into health data responses.
- Apply identical auth requirements to billing and health endpoints.
- GDPR privacy notice must disclose billing data processing and the lawful basis (Article 6(1)(b) -- contractual necessity).
- Stripe dispute responses should contain minimal information -- transaction ID and amount, not "user was tracking their asthma symptoms and cancelled."

**Phase:** Billing phase. Architectural separation established before building endpoints.

---

## Prevention Strategies

### Strategy 1: MFA-Aware Authentication Concern (Addresses Pitfalls 1, 3, 5)

Extend the `Authentication` concern with a two-tier model:

```
Password verified → pending state (session[:pending_user_id], 5-min TTL)
TOTP verified → full session (start_new_session_for, mfa_verified_at set)
API key → full access within scopes (no MFA check, but scopes are limited)
```

The key insight: the `require_authentication` method must distinguish between "no auth at all" (redirect to login), "password only" (redirect to TOTP form), and "fully authenticated" (proceed). API key auth is a separate path that never enters the pending state.

### Strategy 2: Async Webhook Pattern (Addresses Pitfalls 2, 8, 9)

Every Stripe webhook handler follows the same pattern:

```
1. Verify signature (Stripe library, no DB)
2. INSERT event (atomic, unique_by stripe_event_id)
3. Enqueue ProcessStripeEventJob
4. Return 200 OK
```

Total DB time in the request: one INSERT (~1ms). All business logic runs in the Solid Queue job, serialized, with retries. This eliminates SQLite contention in the webhook path entirely.

### Strategy 3: Namespace Separation (Addresses Pitfalls 5, 7, 10, 15)

```
app/controllers/
  application_controller.rb          # Session auth, CSRF, MFA check
  admin/base_controller.rb           # Session auth + role check
  api/v1/base_controller.rb          # API key auth, no CSRF, no sessions
```

`Api::V1::BaseController` inherits from `ActionController::API`, not `ApplicationController`. This physically prevents session/API auth mixing. Each namespace has its own auth concern, its own error handling, its own rate limiting.

### Strategy 4: Phased RBAC Migration (Addresses Pitfall 4)

```
Step 1: Add role enum, keep admin boolean, alias admin? → role check
Step 2: Update toggle_admin and all .admin references
Step 3: Remove admin boolean column
Step 4: Full test suite between each step
```

No step breaks existing functionality. Each step is independently deployable and reversible.

### Strategy 5: Health Data Isolation from Billing (Addresses Pitfalls 6, 11, 12)

Rule: Health data and billing data never cross boundaries.

- Stripe sees: opaque user ID, generic plan name, payment method (via Stripe.js -- never touches our server)
- App database sees: Stripe customer ID, subscription status, plan type
- API responses: billing endpoints and health endpoints are separate
- Deletion: Stripe cleanup is a prerequisite for account deletion, not an afterthought

---

## Phase-Specific Warnings Summary

| Phase | Critical Pitfalls | High Pitfalls | Action Required |
|-------|-------------------|---------------|-----------------|
| MFA | #1 Session Bypass | #13 OTP encryption | Design pending-state auth FIRST |
| RBAC | #4 Dual admin source | #14 Over-engineering | Phased migration with backward compat |
| Stripe Billing | #2 SQLite BUSY | #6 Metadata leaks, #8 Idempotency race, #11 No deletion path | Async webhooks, opaque metadata, deletion flow |
| REST API | #3 API keys bypass MFA | #5 Dual auth divergence, #7 Scope leaks, #10 ID enumeration | Separate namespace, user-scoped queries, rate limits |

---

## Sources

- [Session Puzzling to Bypass Two-Factor Authentication](https://www.invicti.com/blog/web-security/two-interesting-session-related-vulnerabilities) -- MFA bypass via intermediate session state (HIGH confidence)
- [SQLite on Rails -- Improving Concurrency](https://fractaledmind.com/2023/12/11/sqlite-on-rails-improving-concurrency/) -- WAL mode, IMMEDIATE transactions, busy_timeout (HIGH confidence)
- [SQLite on Rails: The How and Why of Optimal Performance](https://fractaledmind.com/2024/04/15/sqlite-on-rails-the-how-and-why-of-optimal-performance/) -- Production SQLite configuration (HIGH confidence)
- [Rails PR #50371: Ensure SQLite transactions default to IMMEDIATE mode](https://github.com/rails/rails/pull/50371) -- Official Rails SQLite change (HIGH confidence)
- [SQLite Concurrent Writes and Database Locked Errors](https://tenthousandmeters.com/blog/sqlite-concurrent-writes-and-database-is-locked-errors/) -- Deep dive on write contention (HIGH confidence)
- [What to Do About SQLITE_BUSY Errors Despite Setting a Timeout](https://berthub.eu/articles/posts/a-brief-post-on-sqlite3-database-locked-despite-timeout/) -- BUSY exceptions with WAL mode (HIGH confidence)
- [Stripe Idempotent Requests API Reference](https://docs.stripe.com/api/idempotent_requests) -- Official Stripe idempotency docs (HIGH confidence)
- [Best Practices for Stripe Webhooks](https://www.stigg.io/blog-posts/best-practices-i-wish-we-knew-when-integrating-stripe-webhooks) -- Webhook handling patterns (MEDIUM confidence)
- [Stripe Privacy Center](https://stripe.com/legal/privacy-center) -- GDPR compliance scope (HIGH confidence)
- [Stripe Data Processing Agreement](https://stripe.com/legal/dpa) -- DPA coverage and limitations (HIGH confidence)
- [Keygen: API Key Authentication in Rails Without Devise](https://keygen.sh/blog/how-to-implement-api-key-authentication-in-rails-without-devise/) -- Dual auth patterns (MEDIUM confidence)
- [Rails 8 API Authentication Mechanisms](https://railsdrop.com/2025/05/31/rails-8-api-app-authentication-mechanisms/) -- API auth in Rails 8 context (MEDIUM confidence)
- Codebase analysis: `Authentication` concern, `SessionsController`, `Admin::BaseController`, `User` model, `database.yml` (HIGH confidence -- direct source inspection)
