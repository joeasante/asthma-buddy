---
status: pending
priority: p2
issue_id: "238"
tags: [code-review, rails, http-semantics, onboarding]
dependencies: []
---

# `skip` Action Uses GET for a State-Mutating Operation

## Problem Statement

`OnboardingController#skip` sets `onboarding_personal_best_done: true` or `onboarding_medication_done: true` on the user, but the route is defined as a GET request. This violates HTTP semantics — GET must be safe (no side effects) and idempotent. Browser prefetchers, link-preview renderers, and crawlers will fire GET requests and could silently mark onboarding steps as done for users who never intended to skip.

## Findings

- `config/routes.rb` line 51: `get "skip/:step", to: "onboarding#skip", as: :skip, constraints: { step: /[1-3]/ }`
- `OnboardingController#skip` calls `Current.user.update!(onboarding_personal_best_done: true)` on GET
- Every other write-path in the app uses POST/PATCH/PUT/DELETE — no other state-mutating GET exists
- Rails CSRF protection does not apply to GET requests, so a malicious `<img src="/onboarding/skip/1">` tag could trigger the skip if the victim is logged in

## Proposed Solutions

### Option 1: Change to PATCH route (Recommended)

**Approach:** Change route to `patch "skip/:step"`. Update skip links in `_step_1.html.erb` and `_step_2.html.erb` to use `button_to` with `method: :patch`.

**Pros:**
- Correct HTTP semantics
- CSRF-protected automatically
- Consistent with all other write routes in the app

**Cons:**
- Requires changing view links to `button_to` (minor HTML change)

**Effort:** 30 minutes

**Risk:** Low

---

### Option 2: Change to POST route

**Approach:** Use `post "skip/:step"` instead. Same view changes required.

**Pros:** Simpler than PATCH conceptually (this is not an update to an existing resource)

**Cons:** PATCH is semantically more accurate (partial update to user record)

**Effort:** 30 minutes

**Risk:** Low

## Recommended Action

Use Option 1 (PATCH). Update route + both step partial skip links.

## Technical Details

**Affected files:**
- `config/routes.rb:51`
- `app/views/onboarding/_step_1.html.erb` — skip link
- `app/views/onboarding/_step_2.html.erb` — skip link
- `test/controllers/onboarding_controller_test.rb` — change `get onboarding_skip_path(1)` to `patch`

## Acceptance Criteria

- [ ] `skip` route uses PATCH (or POST), not GET
- [ ] Skip links in both step partials use `button_to` with correct method
- [ ] Controller tests updated to use `patch onboarding_skip_path`
- [ ] `bin/rails test` passes with no regressions

## Work Log

### 2026-03-10 — Code Review Discovery

**By:** Claude Code (ce:review)

**Actions:** Identified via Rails reviewer and security reviewer. Both flagged GET for state-mutating operation as a FAIL.
