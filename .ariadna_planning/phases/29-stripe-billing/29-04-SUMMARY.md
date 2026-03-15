---
phase: 29-stripe-billing
plan: 04
subsystem: payments
tags: [stripe, pay, billing, trial, pricing, mailer, solid-queue]

requires:
  - phase: 29-stripe-billing (01-03)
    provides: Pay gem setup, billing controller, billing policy, PlanLimits concern, PLANS constant
provides:
  - Public pricing page at /pricing with free vs premium comparison
  - 30-day free trial on Stripe Checkout subscriptions
  - Monthly ($7.99) and annual ($59.99/year) plan selection
  - Trial, paused, and cancelling subscription state handling
  - Health report JSON export gated behind premium
  - Trial reminder email sent 3 days before trial ends
  - Daily TrialReminderJob via Solid Queue recurring schedule
affects: [billing, subscriptions, onboarding, marketing]

tech-stack:
  added: []
  patterns:
    - "Subscription lifecycle states: trialing, active, paused, cancelling, past_due, canceled"
    - "Trial-aware checkout via subscription_data trial_period_days"
    - "Recurring job scheduling via config/recurring.yml"

key-files:
  created:
    - app/controllers/pricing_controller.rb
    - app/views/pricing/show.html.erb
    - app/assets/stylesheets/pricing.css
    - app/mailers/billing_mailer.rb
    - app/views/billing_mailer/trial_ending_soon.html.erb
    - app/views/billing_mailer/trial_ending_soon.text.erb
    - app/jobs/trial_reminder_job.rb
    - test/controllers/pricing_controller_test.rb
    - test/mailers/billing_mailer_test.rb
    - test/jobs/trial_reminder_job_test.rb
  modified:
    - config/initializers/plans.rb
    - app/models/concerns/plan_limits.rb
    - app/controllers/settings/billing_controller.rb
    - app/policies/billing_policy.rb
    - app/views/settings/billing/show.html.erb
    - app/controllers/appointment_summaries_controller.rb
    - app/views/layouts/application.html.erb
    - config/routes.rb
    - config/recurring.yml
    - test/models/plan_limits_test.rb
    - test/controllers/settings/billing_controller_test.rb
    - test/controllers/appointment_summaries_controller_test.rb

key-decisions:
  - "Paused subscriptions do NOT grant premium access (paused? check in premium?)"
  - "Health report JSON export gated via premium? check, HTML remains accessible to all"
  - "Trial reminder email targets users via Pay::Subscription query (status: trialing, trial_ends_at in 3-day window)"
  - "Pricing page uses allow_unauthenticated_access + skip_pundit for public access"
  - "Monthly price is default when no plan param provided to checkout"

patterns-established:
  - "Public page pattern: allow_unauthenticated_access + skip_pundit"
  - "Subscription lifecycle display: badge + contextual messaging per state"
  - "Format-level feature gating: respond_to block checks premium? per format"

duration: 8min
completed: 2026-03-15
---

# Phase 29 Plan 04: Trial, Pricing & Lifecycle Summary

**30-day free trial checkout, public pricing page with monthly/annual options, subscription lifecycle states (trial/pause/cancel), health report export gating, and trial reminder emails via Solid Queue**

## Performance

- **Duration:** 8 min
- **Started:** 2026-03-15T11:01:31Z
- **Completed:** 2026-03-15T11:09:00Z
- **Tasks:** 8
- **Files modified:** 22

## Accomplishments
- PLANS constant expanded with pricing metadata ($7.99/mo, $59.99/yr), trial_days: 30, and health_report_export feature flag
- PlanLimits concern handles all subscription lifecycle states: trialing, active, paused, cancelling, past_due
- Checkout action supports monthly/annual plan selection with 30-day trial via subscription_data
- Public pricing page at /pricing with styled plan cards, FAQ, and auth-aware CTAs
- Health report JSON export gated behind premium (free users get 403, HTML still accessible)
- Trial reminder email (BillingMailer#trial_ending_soon) sent 3 days before trial ends
- TrialReminderJob runs daily at 9am via Solid Queue recurring schedule
- 818 tests passing (36 new), 0 failures

## Task Commits

Each task was committed atomically:

1. **Task 1: Update plans.rb with pricing info** - `6593a31` (feat)
2. **Task 2: Update PlanLimits for trial and paused states** - `7db771e` (feat)
3. **Task 3: Trial-aware checkout with plan selection** - `f9d6f0f` (feat)
4. **Task 4: Billing view for trial and paused states** - `66ad49b` (feat)
5. **Task 5: Gate health report JSON export behind premium** - `3e3bdb9` (feat)
6. **Task 6: Public pricing page and navigation links** - `19bf183` (feat)
7. **Task 7: Trial reminder email and scheduled job** - `e4c9924` (feat)
8. **Task 8: Full test suite verification** - (verification only, no commit)

## Files Created/Modified
- `config/initializers/plans.rb` - Pricing metadata, trial_days, health_report_export flag
- `app/models/concerns/plan_limits.rb` - on_trial?, paused?, trial_ends_at, lifecycle states
- `app/controllers/settings/billing_controller.rb` - Plan param, trial_period_days in checkout
- `app/policies/billing_policy.rb` - Paused users can re-checkout
- `app/views/settings/billing/show.html.erb` - Trial/paused badges, pricing info, plan comparison link
- `app/controllers/appointment_summaries_controller.rb` - JSON export gated behind premium?
- `app/controllers/pricing_controller.rb` - Public pricing page controller
- `app/views/pricing/show.html.erb` - Free vs Premium plan cards with FAQ
- `app/assets/stylesheets/pricing.css` - Pricing page styles
- `app/views/layouts/application.html.erb` - Pricing links in header nav and both footers
- `config/routes.rb` - GET /pricing route
- `app/mailers/billing_mailer.rb` - trial_ending_soon email
- `app/views/billing_mailer/trial_ending_soon.{html,text}.erb` - Email templates
- `app/jobs/trial_reminder_job.rb` - Daily job targeting trialing users
- `config/recurring.yml` - trial_reminders schedule

## Decisions Made
- Paused subscriptions do NOT grant premium access (explicit `!paused?` check in `premium?`)
- Health report JSON export gated via `premium?` check; HTML remains accessible to all users
- Trial reminder targets via `Pay::Subscription` query (status: "trialing", trial_ends_at in 3-day window)
- Pricing page uses `allow_unauthenticated_access` + `skip_pundit` for public access
- Monthly price is default when no plan param provided to checkout

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Created pricing route and controller stub during Task 4**
- **Found during:** Task 4 (Billing view update)
- **Issue:** Billing view links to `pricing_path` which required the route and controller to exist
- **Fix:** Created minimal pricing route, controller, and placeholder view ahead of Task 6
- **Files modified:** config/routes.rb, app/controllers/pricing_controller.rb, app/views/pricing/show.html.erb
- **Verification:** Billing controller tests pass with pricing_path references
- **Committed in:** 19bf183 (completed in Task 6 commit)

**2. [Rule 1 - Bug] Fixed rubocop case statement alignment**
- **Found during:** Task 3 (Billing controller)
- **Issue:** Case statement alignment didn't satisfy rubocop-rails-omakase rules
- **Fix:** Refactored to if/else and ran rubocop -A for correct alignment
- **Files modified:** app/controllers/settings/billing_controller.rb
- **Verification:** `bin/rubocop` clean on file
- **Committed in:** f9d6f0f (Task 3 commit)

**3. [Rule 1 - Bug] Fixed assert_no_enqueued_emails unavailable in ActiveJob::TestCase**
- **Found during:** Task 7 (Trial reminder job tests)
- **Issue:** `assert_no_enqueued_emails` not available in `ActiveJob::TestCase`
- **Fix:** Included `ActionMailer::TestHelper` and used `assert_enqueued_emails 0`
- **Files modified:** test/jobs/trial_reminder_job_test.rb
- **Verification:** All 4 job tests pass
- **Committed in:** e4c9924 (Task 7 commit)

---

**Total deviations:** 3 auto-fixed (2 bugs, 1 blocking)
**Impact on plan:** All auto-fixes necessary for correctness. No scope creep.

## Issues Encountered
None.

## User Setup Required

The following Stripe Dashboard and Rails credentials configuration is needed before billing flows work in production:
- Create monthly Price object ($7.99/month recurring) in Stripe Dashboard
- Create annual Price object ($59.99/year recurring) in Stripe Dashboard
- Store monthly Price ID as `stripe.monthly_price_id` in Rails credentials
- Store annual Price ID as `stripe.annual_price_id` in Rails credentials
- Add `customer.subscription.paused` and `customer.subscription.resumed` to webhook events
- Enable subscription pausing in Stripe Customer Portal settings

## Next Phase Readiness
- All billing features complete: checkout, portal, pricing page, trial, pause, email reminders
- Full test suite (818 tests) passing with no regressions
- Ready for integration testing or production deployment

## Self-Check: PASSED

All 10 created files verified present. All 7 task commits verified in git log.

---
*Phase: 29-stripe-billing*
*Completed: 2026-03-15*
