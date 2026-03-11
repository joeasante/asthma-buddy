# Phase 17: Onboarding Flow — Context

**Gathered:** 2026-03-10 (inline discussion)

---

## Decisions (LOCKED — honor exactly)

### 1. Skip persistence: Permanent boolean flags on User model
Add two boolean columns to `users`:
- `onboarding_personal_best_done:boolean, default: false, null: false`
- `onboarding_medication_done:boolean, default: false, null: false`

Each flag is set to `true` when a step is **either completed or explicitly skipped**. Rationale: session-only skip causes wizard to re-appear every login, which is a known anti-pattern that increases churn. Permanent flags are the industry standard (Slack, Notion, Intercom).

### 2. Partial completion: Resume at incomplete step
On subsequent logins, the wizard shows only the steps where the flag is still `false`. If personal best is done (real or skipped), show only Step 2. If both flags are `true`, never show the wizard. This means wizard state is trivially derived from the two flags.

### 3. Redirect trigger: DashboardController `before_action`
Place `before_action :check_onboarding` in `DashboardController` (not `SessionsController#create`). Rationale: SessionsController only fires on the login POST — it misses users with existing sessions navigating directly to `/dashboard` or via Turbo Drive. DashboardController before_action handles all entry points declaratively.

Redirect logic:
```ruby
def check_onboarding
  return if Current.user.onboarding_personal_best_done? && Current.user.onboarding_medication_done?
  redirect_to onboarding_path
end
```

---

## Claude's Discretion (planner chooses)

- URL structure for OnboardingController (`/onboarding` with step param vs `/onboarding/personal_best` and `/onboarding/medication`)
- Whether OnboardingController uses a single `show` action with `step` routing or separate `personal_best` and `medication` actions
- Visual design of progress indicator (2-step stepper, numbered circles, etc.)
- Reuse strategy for existing form partials (`_personal_best_form`, `_medication_form`)

---

## Deferred Ideas (do NOT include)

- Email reminders for incomplete onboarding
- Animated wizard transitions
- In-app tooltips or product tour overlay
- Onboarding analytics/tracking events
