# Phase 29: Stripe Billing - Research

**Researched:** 2026-03-14
**Domain:** Subscription billing with Stripe via Pay gem
**Confidence:** HIGH

## Summary

Stripe billing for Asthma Buddy is a well-trodden path in Rails. The **Pay gem (v11.4)** is the standard Rails billing engine -- it provides models (`Pay::Customer`, `Pay::Subscription`, `Pay::Charge`), automatic webhook processing, Stripe Checkout session creation, and Stripe Customer Portal integration out of the box. This eliminates the need to hand-roll any billing infrastructure.

The critical integration points for this codebase are: (1) the `email_address` column requires an alias since Pay delegates `email` to the owner model, (2) Pay's webhook controller must bypass Pundit's `verify_authorized` after_action since it has no authenticated user, (3) webhook processing should use Solid Queue (already configured) for async handling, and (4) Pundit policies are already in place from Phase 26 and just need plan-aware conditions added.

**Primary recommendation:** Use `pay` gem v11.4 with `stripe` gem ~> 18.0. Define plans as simple constants (no Plans table needed for two tiers). Gate features via Pundit policy conditions checking `user.pay_customer&.subscription&.active?`. Use Stripe Checkout (hosted) and Stripe Customer Portal (hosted) to avoid handling any card data.

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| [pay](https://github.com/pay-rails/pay) | ~> 11.4 | Billing engine (customers, subscriptions, charges, webhooks) | De facto Rails billing gem; handles Stripe API abstraction, webhook processing, model management |
| [stripe](https://github.com/stripe/stripe-ruby) | ~> 18.0 | Stripe API client (required by Pay) | Official Stripe Ruby SDK |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| stripe CLI | latest | Forward webhooks to localhost in development | During development/testing only |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Pay gem | Raw stripe gem + custom models | Pay saves 500+ lines of webhook handling, model management, and edge case handling. No reason to go raw. |
| Pay gem | Cashier (Laravel port) / Reji | Pay is more mature in Ruby ecosystem, better maintained |
| Stripe Checkout (hosted) | Stripe Elements (embedded) | Checkout is simpler, PCI-compliant by default, auto-updates. Elements only needed for deeply custom UIs. |

**Installation:**
```bash
bundle add pay --version "~> 11.4"
bundle add stripe --version "~> 18.0"
bin/rails pay:install:migrations
bin/rails db:migrate
```

## Architecture Patterns

### Recommended Project Structure

```
app/
  models/
    user.rb                           # Add pay_customer, alias_attribute
    concerns/
      plan_limits.rb                  # Plan-aware feature limit methods
  controllers/
    settings/
      billing_controller.rb           # Billing settings page, checkout, portal
  policies/
    # Existing policies gain plan-aware conditions
  views/
    settings/
      billing/
        show.html.erb                 # Current plan, status, manage link
  webhooks/
    stripe_subscription_handler.rb    # Custom webhook listener (optional)

config/
  initializers/
    pay.rb                            # Pay configuration
```

### Pattern 1: Pay Customer Setup with email_address Alias

**What:** Pay delegates `email` to the owner model. Asthma Buddy uses `email_address`, not `email`. An alias bridges this gap.
**When to use:** Always -- this is required for Pay to function.
**Example:**
```ruby
# Source: https://github.com/pay-rails/pay/blob/main/app/models/pay/customer.rb
# Pay::Customer does: delegate :email, to: :owner, allow_nil: true
#
# So the User model needs:
class User < ApplicationRecord
  alias_attribute :email, :email_address

  pay_customer default_payment_processor: :stripe
end
```

**Confidence:** HIGH -- verified by reading Pay::Customer source code. The delegate call is `delegate :email, to: :owner, allow_nil: true`.

### Pattern 2: Stripe Checkout via Pay

**What:** Create a Stripe Checkout session and redirect the user to Stripe's hosted payment page.
**When to use:** When a free user clicks "Upgrade to Premium".
**Example:**
```ruby
# Source: https://github.com/pay-rails/pay/blob/main/docs/stripe/8_stripe_checkout.md
class Settings::BillingController < Settings::BaseController
  def checkout
    current_user = Current.user
    current_user.set_payment_processor :stripe

    @checkout_session = current_user.payment_processor.checkout(
      mode: "subscription",
      line_items: "price_XXXXXXXXXXXX",  # Stripe Price ID from dashboard
      success_url: settings_billing_url(session_id: "{CHECKOUT_SESSION_ID}"),
      cancel_url: settings_billing_url
    )

    redirect_to @checkout_session.url, allow_other_host: true
  end
end
```

**Important:** The link/button to checkout MUST use `data: { turbo: false }` to prevent Turbo from intercepting the redirect to Stripe's external domain.

### Pattern 3: Stripe Customer Portal via Pay

**What:** Let subscribed users manage their subscription (cancel, update payment, view invoices) through Stripe's hosted portal.
**When to use:** When a premium user clicks "Manage Subscription" on the billing page.
**Example:**
```ruby
# Source: https://github.com/pay-rails/pay/blob/main/docs/stripe/8_stripe_checkout.md
def portal
  portal_session = Current.user.payment_processor.billing_portal(
    return_url: settings_billing_url
  )
  redirect_to portal_session.url, allow_other_host: true
end
```

### Pattern 4: Plan-Aware Pundit Policies

**What:** Extend existing Pundit policies to check subscription status for premium features.
**When to use:** Any policy that gates premium-only features.
**Example:**
```ruby
# In a policy that gates a premium feature:
class SomeFeaturePolicy < ApplicationPolicy
  def index?
    user.premium?  # Delegate to a User method
  end
end

# In User model:
class User < ApplicationRecord
  def premium?
    payment_processor&.subscription&.active? || admin?
  end

  def free?
    !premium?
  end

  def plan_name
    premium? ? "Premium" : "Free"
  end
end
```

### Pattern 5: Webhook Idempotency

**What:** Stripe may deliver the same webhook event multiple times. Processing must be idempotent.
**When to use:** All webhook handling.
**How Pay handles it:** Pay's built-in webhook handlers use `find_or_initialize_by` patterns with Stripe resource IDs, making them naturally idempotent. Pay::Subscription records are keyed by `processor_id` (the Stripe subscription ID), so duplicate events just update the same record.
**For custom handlers:** Track processed event IDs in a dedicated table or use database unique constraints.

**Confidence:** MEDIUM -- Pay's idempotency approach is inferred from its model design (unique processor_id fields). Custom handlers need explicit idempotency.

### Pattern 6: Webhook Controller Bypassing Pundit

**What:** Pay's webhook controller receives unsigned POST requests from Stripe (verified by signing secret, not user auth). It must bypass Pundit's `verify_authorized`.
**When to use:** Always -- Pay mounts its own engine routes.
**How it works:** Pay::Engine mounts at `/pay/webhooks/stripe` separately from the main app routes. Since it is an engine, it uses its own controller inheritance and does NOT go through `ApplicationController`, so Pundit's `after_action :verify_authorized` does not apply.

**Confidence:** HIGH -- Pay is a Rails Engine with its own controllers.

### Anti-Patterns to Avoid

- **Storing card data in your database:** Never. Stripe Checkout and Customer Portal handle all PCI-sensitive data. Asthma Buddy never sees card numbers.
- **Synchronous webhook processing:** Pay processes webhooks inline in its controller, but the webhook events trigger Stripe API calls that are inherently network-bound. For SQLite's single-writer constraint, use `config.active_job.queue_adapter = :solid_queue` (already configured) and consider wrapping heavy custom handlers in background jobs.
- **Building a custom payment form:** Stripe Checkout (hosted) is always better for a small app. Less code, automatic SCA handling, automatic localization.
- **Polling Stripe for subscription status:** Webhooks push state changes. Trust the webhook-synced `Pay::Subscription` record.
- **Multiple plans table for two tiers:** Overkill. Use constants or a simple hash. A `Plan` model makes sense at 5+ plans.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Subscription state machine | Custom state tracking | Pay::Subscription status fields | Pay tracks active, canceled, past_due, trialing, paused automatically via webhooks |
| Webhook signature verification | Custom HMAC verification | Pay's built-in Stripe webhook controller | Handles signature verification, event parsing, and routing automatically |
| Customer portal | Custom subscription management UI | Stripe Customer Portal | Cancel, update payment method, view invoices -- all hosted by Stripe, zero maintenance |
| Payment page | Custom checkout form | Stripe Checkout | PCI compliance, SCA, localization, multiple payment methods -- all free |
| Retry logic for failed payments | Custom dunning system | Stripe's built-in retry logic + Pay webhooks | Stripe retries failed payments automatically and sends webhook events |

**Key insight:** For a two-tier (free/premium) SaaS, virtually all billing UI should be hosted by Stripe. The app only needs: (1) a billing settings page showing current plan status, (2) a "Subscribe" button that redirects to Stripe Checkout, and (3) a "Manage" button that redirects to Stripe Customer Portal.

## Common Pitfalls

### Pitfall 1: Forgetting the email Alias

**What goes wrong:** Pay gem calls `owner.email` on the User model. Without `alias_attribute :email, :email_address`, this returns nil or raises NoMethodError. Stripe customer creation fails silently or with cryptic errors.
**Why it happens:** Rails 8 authentication generator uses `email_address`, but Pay (and most gems) expect `email`.
**How to avoid:** Add `alias_attribute :email, :email_address` to User model BEFORE `pay_customer`.
**Warning signs:** Stripe customer records created with blank email; "email is required" errors from Stripe API.

### Pitfall 2: Not Disabling Turbo on Checkout/Portal Links

**What goes wrong:** Turbo intercepts the redirect to Stripe's external domain. The user sees a Turbo error or the page just hangs.
**Why it happens:** Turbo Frames/Drive try to fetch the response as HTML and fail on cross-origin redirects.
**How to avoid:** Use `data: { turbo: false }` on all links/buttons that redirect to Stripe.
**Warning signs:** Checkout button appears to do nothing; console shows Turbo fetch errors.

### Pitfall 3: Not Configuring Webhooks Before Testing Checkout

**What goes wrong:** Stripe Checkout completes payment successfully, but the app never creates a Pay::Subscription record. The user paid but the app thinks they are still free.
**Why it happens:** Pay relies on webhook events (`customer.subscription.created`) to create subscription records. Without webhooks, the data never arrives.
**How to avoid:** Set up Stripe CLI webhook forwarding in development BEFORE testing checkout. In production, configure the webhook endpoint in Stripe Dashboard before deploying.
**Warning signs:** Successful Stripe payments but empty `pay_subscriptions` table.

### Pitfall 4: SQLite Write Contention on Webhooks

**What goes wrong:** Under load, webhook processing can fail with SQLite BUSY errors if multiple webhooks arrive simultaneously.
**Why it happens:** SQLite allows only one writer at a time. Rapid webhook bursts (e.g., subscription created + charge succeeded arriving milliseconds apart) can cause lock contention.
**How to avoid:** Pay processes webhooks synchronously in the controller, which is fine for most small apps. If problems arise, process webhook payloads via Solid Queue jobs. Rails 8 SQLite configuration with WAL mode and busy_timeout helps significantly.
**Warning signs:** 500 errors on webhook endpoint; `SQLite3::BusyException` in logs.

### Pitfall 5: Not Handling Grace Periods on Cancellation

**What goes wrong:** User cancels subscription but immediately loses access to premium features, even though they paid through the end of the billing period.
**Why it happens:** Checking only `subscription.active?` without considering `ends_at`.
**How to avoid:** Pay's `subscription.active?` already handles this correctly -- it returns true during the grace period (between cancellation and `ends_at`). Use `subscription.active?` not custom date checks.
**Warning signs:** Angry users who paid for a month but lost access immediately after canceling.

### Pitfall 6: Hardcoding Stripe Price IDs

**What goes wrong:** Price IDs differ between test and live mode. App works in test but breaks in production.
**Why it happens:** Developers hardcode test-mode price IDs (e.g., `price_1XXXXX`).
**How to avoid:** Store Stripe Price IDs in Rails credentials, separate for each environment.
**Warning signs:** "No such price" errors in production.

## Code Examples

### Pay Initializer Configuration

```ruby
# config/initializers/pay.rb
# Source: https://github.com/pay-rails/pay/blob/main/docs/2_configuration.md
Pay.setup do |config|
  config.business_name = "Asthma Buddy"
  config.business_address = "Your address"
  config.application_name = "Asthma Buddy"
  config.support_email = "support@example.com"

  config.enabled_processors = [:stripe]
  config.send_emails = true
end
```

### Stripe Credentials Configuration

```yaml
# config/credentials/development.yml.enc (via rails credentials:edit --environment=development)
stripe:
  private_key: sk_test_XXXX
  public_key: pk_test_XXXX
  signing_secret:
    - whsec_XXXX

# config/credentials/production.yml.enc
stripe:
  private_key: sk_live_XXXX
  public_key: pk_live_XXXX
  signing_secret:
    - whsec_XXXX
```

### User Model with Pay Integration

```ruby
# Source: https://github.com/pay-rails/pay/blob/main/docs/1_installation.md
class User < ApplicationRecord
  # Pay requires `email` -- our column is `email_address`
  alias_attribute :email, :email_address

  pay_customer default_payment_processor: :stripe

  # Plan helpers
  def premium?
    payment_processor&.subscription&.active? || admin?
  end

  def free?
    !premium?
  end

  def plan_name
    premium? ? "Premium" : "Free"
  end

  def subscription_status
    sub = payment_processor&.subscription
    return "none" unless sub
    if sub.active? && sub.ends_at.present?
      "cancelling"  # Active but will end
    elsif sub.active?
      "active"
    else
      sub.status  # past_due, canceled, etc.
    end
  end

  def next_billing_date
    payment_processor&.subscription&.current_period_end
  end
end
```

### Billing Controller

```ruby
class Settings::BillingController < Settings::BaseController
  def show
    authorize :billing
    @user = Current.user
    @subscription = @user.payment_processor&.subscription
  end

  def checkout
    authorize :billing, :checkout?
    user = Current.user
    user.set_payment_processor :stripe

    checkout_session = user.payment_processor.checkout(
      mode: "subscription",
      line_items: Rails.application.credentials.dig(:stripe, :premium_price_id),
      success_url: settings_billing_url,
      cancel_url: settings_billing_url
    )

    redirect_to checkout_session.url, allow_other_host: true
  end

  def portal
    authorize :billing, :portal?
    portal_session = Current.user.payment_processor.billing_portal(
      return_url: settings_billing_url
    )
    redirect_to portal_session.url, allow_other_host: true
  end
end
```

### Custom Webhook Listener (Optional)

```ruby
# app/webhooks/stripe_subscription_handler.rb
# Source: https://github.com/pay-rails/pay/blob/main/docs/7_webhooks.md
class StripeSubscriptionHandler
  def call(event)
    # Pay already handles creating/updating Pay::Subscription records.
    # Use custom listeners only for side effects like notifications.
    pay_subscription = Pay::Subscription.find_by(processor_id: event.data.object.id)
    return unless pay_subscription

    case event.type
    when "customer.subscription.deleted"
      # Notify user their subscription ended
      BillingMailer.subscription_ended(pay_subscription.customer.owner).deliver_later
    end
  end
end

# config/initializers/pay.rb (add to setup block)
Pay::Webhooks.delegator.subscribe(
  "stripe.customer.subscription.deleted",
  StripeSubscriptionHandler.new
)
```

### Billing Policy

```ruby
# app/policies/billing_policy.rb
class BillingPolicy < ApplicationPolicy
  def show?
    true  # All authenticated users can view billing page
  end

  def checkout?
    user.free?  # Only free users can initiate checkout
  end

  def portal?
    user.premium?  # Only premium users can access portal
  end
end
```

### Feature Gating in Existing Policies

```ruby
# Example: Gating API access for premium users
# Modify existing policy to add plan check:
class ApiKeyPolicy < ApplicationPolicy
  def show?
    user.premium?  # Only premium users get API keys
  end

  def create?
    user.premium?
  end
end
```

### Testing Webhooks (Minitest)

```ruby
# test/controllers/pay/webhooks_controller_test.rb
class Pay::WebhooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @user.set_payment_processor :stripe
    @user.payment_processor.update!(processor_id: "cus_test123")
  end

  test "handles subscription created webhook idempotently" do
    payload = {
      id: "evt_test123",
      type: "customer.subscription.created",
      data: { object: { id: "sub_test123", customer: "cus_test123", status: "active" } }
    }.to_json

    # First delivery creates subscription
    post "/pay/webhooks/stripe", params: payload,
      headers: stripe_webhook_headers(payload)
    assert_response :success

    # Second delivery (duplicate) does not create duplicate
    post "/pay/webhooks/stripe", params: payload,
      headers: stripe_webhook_headers(payload)
    assert_response :success
    assert_equal 1, Pay::Subscription.where(processor_id: "sub_test123").count
  end

  private

  def stripe_webhook_headers(payload)
    timestamp = Time.now.to_i
    signing_secret = Rails.application.credentials.dig(:stripe, :signing_secret)&.first || "whsec_test"
    signature = Stripe::Webhook::Signature.compute_signature(timestamp, payload, signing_secret)
    {
      "HTTP_STRIPE_SIGNATURE" => "t=#{timestamp},v1=#{signature}",
      "CONTENT_TYPE" => "application/json"
    }
  end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `include Pay::Billable` | `pay_customer` class method | Pay v3+ (2021) | Simpler API, less module pollution |
| Custom Stripe::Event handling | Pay handles all webhook events | Pay v6+ (2023) | No need to write webhook handlers for standard billing events |
| stripe_event gem | Pay's built-in webhook routing | Pay v3+ | One less dependency |
| Stripe.js Elements for checkout | Stripe Checkout (hosted) | Stripe 2019+ | No card data touches your server, automatic SCA |
| Custom cancellation/portal pages | Stripe Customer Portal | Stripe 2020+ | Zero maintenance subscription management UI |

**Deprecated/outdated:**
- `include Pay::Billable`: Replaced by `pay_customer` class method in Pay v3+
- `stripe_event` gem: Pay handles webhook routing internally
- Stripe Charges API: Replaced by PaymentIntents API (Pay uses PaymentIntents)

## Webhook Events Handled by Pay

Pay automatically processes these Stripe webhook events (source: [Pay docs](https://github.com/pay-rails/pay/blob/main/docs/stripe/5_webhooks.md)):

| Event | What Pay Does |
|-------|---------------|
| `charge.succeeded` | Creates Pay::Charge record |
| `charge.refunded` | Updates Pay::Charge refund status |
| `customer.subscription.created` | Creates Pay::Subscription record |
| `customer.subscription.updated` | Updates Pay::Subscription status/plan |
| `customer.subscription.deleted` | Marks Pay::Subscription as canceled |
| `customer.subscription.trial_will_end` | Triggers trial ending email |
| `invoice.payment_action_required` | Triggers payment action required email |
| `invoice.payment_failed` | Triggers payment failed email |
| `payment_method.attached` | Creates Pay::PaymentMethod record |
| `payment_method.updated` | Updates Pay::PaymentMethod record |
| `payment_method.detached` | Removes Pay::PaymentMethod record |
| `checkout.session.completed` | Processes completed checkout |
| `checkout.session.async_payment_succeeded` | Processes async payment completion |

**All of these must be enabled in the Stripe Dashboard webhook endpoint configuration.**

## Plan Definition Strategy

For a simple free/premium two-tier model, define plans as constants rather than a database table:

```ruby
# config/initializers/plans.rb
PLANS = {
  free: {
    name: "Free",
    features: {
      symptom_log_history_days: 30,
      api_access: false,
      export_data: false
    }
  },
  premium: {
    name: "Premium",
    stripe_price_id: Rails.application.credentials.dig(:stripe, :premium_price_id),
    features: {
      symptom_log_history_days: nil,  # unlimited
      api_access: true,
      export_data: true
    }
  }
}.freeze
```

This avoids unnecessary database complexity. When you need 5+ plans, migrate to a Plans table.

## Open Questions

1. **Which features should be premium-gated?**
   - What we know: Requirements mention "restricted API access, limited history" for free users
   - What's unclear: Exact feature limits (how many days of history? which API endpoints?)
   - Recommendation: Planner should define specific limits. Suggested defaults: free gets 30 days history, no API access, no data export. Premium gets unlimited everything.

2. **Trial period?**
   - What we know: Pay supports `trial_period_days` in checkout session
   - What's unclear: Whether Asthma Buddy wants a trial period
   - Recommendation: Skip trial for MVP. Easy to add later (single parameter in checkout call).

3. **Stripe test mode price ID management**
   - What we know: Price IDs differ between test and live Stripe modes
   - What's unclear: How credentials are structured per environment
   - Recommendation: Use per-environment credentials (`development.yml.enc`, `production.yml.enc`) with separate price IDs.

4. **Pay gem email sending**
   - What we know: Pay sends transactional emails (receipts, payment failed, trial ending) by default
   - What's unclear: Whether these should be customized for Asthma Buddy branding
   - Recommendation: Enable default Pay emails for MVP. Customize mailer views later if needed.

## Sources

### Primary (HIGH confidence)
- [Pay gem GitHub](https://github.com/pay-rails/pay) - v11.4, installation, configuration, model structure
- [Pay installation docs](https://github.com/pay-rails/pay/blob/main/docs/1_installation.md) - email field requirements, migration setup
- [Pay configuration docs](https://github.com/pay-rails/pay/blob/main/docs/2_configuration.md) - Stripe credential setup, initializer options
- [Pay Stripe Checkout docs](https://github.com/pay-rails/pay/blob/main/docs/stripe/8_stripe_checkout.md) - Checkout session creation, Turbo caveat, billing portal
- [Pay webhooks docs](https://github.com/pay-rails/pay/blob/main/docs/stripe/5_webhooks.md) - Complete event list, webhook endpoint setup
- [Pay::Customer source](https://github.com/pay-rails/pay/blob/main/app/models/pay/customer.rb) - Confirmed `delegate :email, to: :owner`
- [Pay subscriptions docs](https://github.com/pay-rails/pay/blob/main/docs/6_subscriptions.md) - Subscription status methods, cancellation, grace periods

### Secondary (MEDIUM confidence)
- [Stripe idempotency docs](https://docs.stripe.com/api/idempotent_requests) - Webhook idempotency best practices
- [Stripe webhook docs](https://docs.stripe.com/webhooks) - Event delivery, retry behavior
- [Stripe CLI docs](https://docs.stripe.com/stripe-cli/use-cli) - Local webhook forwarding

### Tertiary (LOW confidence)
- [Testing Stripe webhooks with Minitest](https://store.kylekeesling.com/posts/2023/09/testing-stripe-webhooks-with-minitest) - Webhook test patterns (needs validation against current Pay version)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- Pay gem is the established Rails billing solution, verified via official docs and source code
- Architecture: HIGH -- Patterns verified against Pay documentation and Asthma Buddy codebase structure
- Pitfalls: HIGH -- email alias issue confirmed by reading Pay::Customer source; Turbo issue documented in Pay's own Checkout docs
- Testing: MEDIUM -- webhook testing patterns from community sources, not Pay's own test suite

**Research date:** 2026-03-14
**Valid until:** 2026-04-14 (Pay gem is stable, Stripe API is stable)
