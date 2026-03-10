---
status: pending
priority: p3
issue_id: "246"
tags: [code-review, architecture, onboarding, documentation]
dependencies: []
---

# Onboarding Gate Scope Is Dashboard-Only — Intent Undocumented

## Problem Statement

`check_onboarding` is only on `DashboardController`. All other data controllers (`PeakFlowReadingsController`, `SymptomLogsController`, `MedicationsController`, `HealthEventsController`, etc.) have no onboarding guard. A user who knows the URL can reach `/peak-flow-readings/new` without completing onboarding. Whether this is intentional (soft gate) or an oversight (incomplete implementation) is undocumented.

## Findings

- `dashboard_controller.rb:4` — only controller with `before_action :check_onboarding`
- Architecture reviewer: "A newly registered user who knows the URL for `/peak-flow-readings/new` can access it directly without completing onboarding"
- Security reviewer: "Decide explicitly whether onboarding is a hard gate or a soft gate"
- Models gracefully handle missing personal best (`@has_personal_best` flag exists in `PeakFlowReadingsController`)
- Current behaviour: functional bypass exists, app handles it without crashing

## Proposed Solutions

### Option 1: Document the soft-gate decision with a comment

**Approach:** Add a comment to `DashboardController#check_onboarding` explaining that onboarding is a soft gate — users can bypass by navigating directly to feature URLs, which is intentional.

**Effort:** 5 minutes  **Risk:** None

---

### Option 2: Move guard to `ApplicationController` (hard gate)

**Approach:** Move `check_onboarding` to `ApplicationController` with `skip_before_action` on `OnboardingController`, `SessionsController`, `RegistrationsController`, `HomeController`, etc.

**Pros:** Enforces onboarding before any data entry
**Cons:** More invasive; many controllers need `skip_before_action`

**Effort:** 45 minutes  **Risk:** Medium (broad change)

## Recommended Action

Option 1 unless the product spec says hard gate. Document the decision so future developers don't add redundant guards on individual controllers.

## Technical Details

- `app/controllers/dashboard_controller.rb` — add comment

## Acceptance Criteria

- [ ] The onboarding gate scope decision is documented in code (comment in `check_onboarding` or a DECISIONS.md entry)
- [ ] `bin/rails test` passes

## Work Log

### 2026-03-10 — Code Review Discovery

**By:** Claude Code (ce:review)
