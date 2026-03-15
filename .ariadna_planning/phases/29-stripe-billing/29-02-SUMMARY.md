---
phase: 29-stripe-billing
plan: 02
subsystem: payments
tags: [stripe, billing, checkout, portal, pundit, settings, ui]

# Dependency graph
requires:
  - phase: 29-stripe-billing
    provides: "Pay gem tables, PlanLimits concern, PLANS constant, pay_customer integration"
provides:
  - "Billing settings page at /settings/billing with plan status display"
  - "Stripe Checkout integration for free-to-premium upgrade flow"
  - "Stripe Customer Portal integration for subscription management"
  - "BillingPolicy (headless Pundit) gating checkout and portal access"
  - "Billing card in settings navigation grid"
affects: [29-stripe-billing, feature-gating, settings-ui]

# Tech tracking
tech-stack:
  added: []
  patterns: [button_to with data-turbo false for external redirects, allow_other_host on redirect_to for Stripe URLs, headless Pundit policy for billing]

key-files:
  created:
    - app/controllers/settings/billing_controller.rb
    - app/policies/billing_policy.rb
    - app/views/settings/billing/show.html.erb
    - test/controllers/settings/billing_controller_test.rb
  modified:
    - config/routes.rb
    - app/views/settings/show.html.erb

key-decisions:
  - "button_to generates data-turbo=false on <button> element, not form — tests adjusted accordingly"
  - "Admins see Premium (Admin) label but no subscription management buttons"
  - "Policy gates: checkout for free only, portal for premium non-admin only"

patterns-established:
  - "Billing controller inherits Settings::BaseController like other settings sub-controllers"
  - "Headless policy pattern: authorize :billing, :action? for non-model authorization"
  - "External redirect pattern: allow_other_host: true + data-turbo: false for Stripe URLs"

# Metrics
duration: 4min
completed: 2026-03-15
---

# Phase 29 Plan 02: Billing Settings UI Summary

**Billing settings page with Stripe Checkout upgrade flow, Customer Portal management, Pundit policy enforcement, and 14 controller tests**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-15T00:54:03Z
- **Completed:** 2026-03-15T00:58:18Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Billing settings page at /settings/billing showing plan name, status badge, and next billing date
- Free users see "Upgrade to Premium" button (POST to Stripe Checkout); premium users see "Manage Subscription" (POST to Stripe Portal)
- BillingPolicy enforces checkout for free users only and portal for premium non-admin users only
- Billing card added to settings navigation grid (before API Key card) with premium badge for subscribers
- 14 controller tests covering rendering, plan display, policy enforcement, data-turbo attributes, and settings nav
- Full suite: 776 tests, 0 failures

## Task Commits

Each task was committed atomically:

1. **Task 1: Add billing routes, controller, and Pundit policy** - `b45b6d2` (feat)
2. **Task 2: Create billing view, update settings navigation, and write controller tests** - `90a613f` (feat)

## Files Created/Modified
- `app/controllers/settings/billing_controller.rb` - Billing controller with show/checkout/portal actions
- `app/policies/billing_policy.rb` - Headless Pundit policy gating checkout and portal access
- `app/views/settings/billing/show.html.erb` - Billing page with plan status, limits, and action buttons
- `test/controllers/settings/billing_controller_test.rb` - 14 tests for billing controller
- `config/routes.rb` - Added billing routes (GET show, POST checkout, POST portal)
- `app/views/settings/show.html.erb` - Added billing card to settings navigation grid

## Decisions Made
- button_to with `data: { turbo: false }` places the attribute on the `<button>` element (not the form) — test selectors adjusted accordingly
- Admins see "Premium (Admin)" label but no subscription management buttons since they have no Stripe subscriptions
- Policy enforcement: checkout restricted to free users, portal restricted to premium non-admin users

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed test selectors for button_to HTML output**
- **Found during:** Task 2 (controller tests)
- **Issue:** Tests used `input[value='...']` selectors but Rails `button_to` generates `<button>` elements, not `<input>` elements. Also `data-turbo` attribute goes on `<button>`, not `<form>`.
- **Fix:** Changed selectors to `button` text matching and nested form > button assertions
- **Files modified:** test/controllers/settings/billing_controller_test.rb
- **Verification:** All 14 tests pass
- **Committed in:** 90a613f (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Auto-fix necessary for test correctness. No scope creep.

## Issues Encountered
None.

## User Setup Required
None beyond Plan 01 requirements (Stripe API keys in Rails credentials).

## Next Phase Readiness
- Billing UI complete: users can view plan, initiate checkout, and manage subscriptions
- Ready for Plan 03: feature gating based on plan limits (restricting history, API access, data export)

## Self-Check: PASSED

All 4 created files verified on disk. Both task commits (b45b6d2, 90a613f) verified in git log.

---
*Phase: 29-stripe-billing*
*Completed: 2026-03-15*
