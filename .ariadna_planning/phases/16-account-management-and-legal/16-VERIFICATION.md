---
phase: 16-account-management-and-legal
verified: 2026-03-10T14:55:14Z
status: passed
score: 17/17 must-haves verified | security: 0 critical, 0 high | performance: 0 high
---

# Phase 16: Account Management and Legal — Verification Report

**Phase Goal:** Implement account deletion (GDPR right to erasure), enrich Terms of Service and Privacy Policy with UK GDPR-appropriate content, and add a dismissible cookie notice banner. All legal/compliance requirements for public launch.
**Verified:** 2026-03-10T14:55:14Z
**Status:** PASSED
**Re-verification:** No — initial verification

---

## Plan 01: Account Deletion

### Observable Truths

| #   | Truth | Status | Evidence |
| --- | ----- | ------ | -------- |
| 1 | Authenticated user can see a Danger Zone section at the bottom of the settings page | VERIFIED | `settings/show.html.erb` line 40: `<section class="danger-zone" aria-labelledby="danger-zone-heading">` |
| 2 | Danger Zone contains a form with a text field for typing DELETE and a submit button | VERIFIED | `settings/show.html.erb` lines 51-63: `form_with url: account_path, method: :delete` with confirmation text_field and submit |
| 3 | Submitting the form with the exact text DELETE destroys the user record and all dependent data | VERIFIED | `accounts_controller.rb`: `params[:confirmation] == "DELETE"` → `Current.user.destroy` + `reset_session`; User model has `dependent: :destroy` on all 7 associations (symptom_logs, peak_flow_readings, personal_best_records, medications, dose_logs, health_events, sessions) |
| 4 | After deletion the user is redirected to the root path with a flash notice confirming deletion | VERIFIED | `accounts_controller.rb` line 8: `redirect_to root_path, notice: "Your account and all associated data have been permanently deleted."` |
| 5 | Submitting with wrong confirmation text re-renders the settings page with an error; no data is deleted | VERIFIED | `accounts_controller.rb` line 10: `redirect_to settings_path, alert: "Account not deleted. You must type DELETE exactly to confirm."`; test passing: "DELETE /account with wrong confirmation does not destroy user" |
| 6 | Unauthenticated request to DELETE /account is redirected to sign in | VERIFIED | Test "unauthenticated DELETE /account redirects to sign in" passes; Authentication module handles this via `before_action :require_authentication` |
| 7 | User cannot log back in after their account has been deleted | VERIFIED | Test "deleted user cannot sign back in" passes (redirected to `new_session_path` with alert) |

**Score:** 7/7 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `app/controllers/accounts_controller.rb` | AccountsController with destroy action | VERIFIED | Exists, substantive (13 lines, typed confirmation guard, Current.user.destroy, reset_session), wired via `resource :account` route |
| `app/views/settings/show.html.erb` | Settings page with Danger Zone deletion form | VERIFIED | Exists, 66 lines with full Danger Zone section, `account_path` form action |
| `test/controllers/accounts_controller_test.rb` | Controller tests for account deletion | VERIFIED | Exists, 5 tests, all 7 assertions pass (0 failures) |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| `settings/show.html.erb` | `AccountsController#destroy` | `form_with url: account_path, method: :delete` | WIRED | Line 51: `form_with url: account_path, method: :delete` confirmed |
| `accounts_controller.rb` | `Current.user.destroy` | `params[:confirmation] == "DELETE"` check then destroy | WIRED | Line 6: `Current.user.destroy` confirmed |

---

## Plan 02: Terms of Service and Privacy Policy

### Observable Truths

| #   | Truth | Status | Evidence |
| --- | ----- | ------ | -------- |
| 1 | GET /terms is accessible without authentication and renders a Terms of Service page | VERIFIED | Route `get "terms", to: "pages#terms"` exists; PagesController has no authentication requirement; `terms.html.erb` exists with `content_for :title, "Terms of Service — Asthma Buddy"` |
| 2 | GET /privacy is accessible without authentication and renders a Privacy Policy page | VERIFIED | Route `get "privacy", to: "pages#privacy"` exists; `privacy.html.erb` exists with `content_for :title, "Privacy Policy — Asthma Buddy"` |
| 3 | Both pages contain substantive UK GDPR-compliant content — not lorem ipsum | VERIFIED | Terms: 49 lines, 10 h2 sections, no lorem ipsum; Privacy: 76 lines, 10 h2 sections, no lorem ipsum — all content meaningful and legally relevant |
| 4 | Both pages are linked from the footer on every page (authenticated and unauthenticated) | VERIFIED | `application.html.erb` lines 126-127 (authenticated footer) and 134-135 (unauthenticated footer): both link to `privacy_path` and `terms_path` |
| 5 | Privacy Policy page references the user's right to delete their account and erasure rights | VERIFIED | `privacy.html.erb` line 56: "Right to erasure: You have the right to request deletion of your personal data ('the right to be forgotten'). You can exercise this right immediately by deleting your account from the Settings page." |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `app/views/pages/terms.html.erb` | Terms of Service page with UK GDPR-appropriate content | VERIFIED | Exists, 49 lines, 10 sections: About, Eligibility (16+ UK GDPR age), Account security, Acceptable use, Health data disclaimer, Service availability, Termination, Changes (14-day notice), Governing law (England and Wales), Contact |
| `app/views/pages/privacy.html.erb` | Privacy Policy page with UK GDPR content | VERIFIED | Exists, 76 lines, 10 sections: Who we are, Data collected (special category Article 9), Lawful basis (Art. 6(1)(b), Art. 9(2)(a), Art. 6(1)(f)), Special category health data, Storage (bcrypt, UK/EEA), Retention (30-day erasure), All 7 UK GDPR rights, Cookies (PECR), Changes, ICO complaints route |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| `app/views/layouts/application.html.erb` | `app/views/pages/terms.html.erb` | `link_to "Terms", terms_path` | WIRED | Lines 127 and 135: both authenticated and unauthenticated footer sections contain `terms_path` |
| `app/views/layouts/application.html.erb` | `app/views/pages/privacy.html.erb` | `link_to "Privacy", privacy_path` | WIRED | Lines 126 and 134: both authenticated and unauthenticated footer sections contain `privacy_path` |

---

## Plan 03: Cookie Notice Banner

### Observable Truths

| #   | Truth | Status | Evidence |
| --- | ----- | ------ | -------- |
| 1 | A first-time visitor sees the cookie notice banner at the bottom of the viewport | VERIFIED | `application_controller.rb` line 22: `before_action :set_cookie_notice_flag`; `application.html.erb` line 117: `render "layouts/cookie_notice" if @show_cookie_notice`; `set_cookie_notice_flag` sets `@show_cookie_notice = !session[:cookie_notice_shown]`, so first visit (no session flag) renders banner |
| 2 | The banner contains a brief informational message and an X dismiss button | VERIFIED | `_cookie_notice.html.erb`: `<p class="cookie-notice-text">This site uses a session cookie...</p>` + `button_to cookie_notice_dismiss_path` with SVG X icon |
| 3 | Clicking the dismiss button hides the banner and sets session[:cookie_notice_shown] | VERIFIED | Dismiss button posts to `cookie_notice_dismiss_path`; `cookie_notices_controller.rb` line 7: `session[:cookie_notice_shown] = true`; Stimulus controller (`cookie_notice_controller.js`) adds `cookie-notice--dismissed` class on `dismiss()` action |
| 4 | On subsequent page visits within the same session the banner does not reappear | VERIFIED | `set_cookie_notice_flag` sets `@show_cookie_notice = !session[:cookie_notice_shown]`; once session flag is `true`, `@show_cookie_notice` is `false`, so layout does not render the partial |
| 5 | The banner is accessible — dismiss button has an aria-label | VERIFIED | `_cookie_notice.html.erb` line 13: `aria: { label: "Dismiss cookie notice" }`; banner also has `role="region"` and `aria-label="Cookie notice"` |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `app/controllers/cookie_notices_controller.rb` | CookieNoticesController#dismiss action | VERIFIED | Exists, 10 lines, `allow_unauthenticated_access`, sets `session[:cookie_notice_shown] = true`, returns `head :no_content` |
| `app/views/layouts/_cookie_notice.html.erb` | Cookie notice banner partial | VERIFIED | Exists, 19 lines, `cookie-notice` class, accessible markup, Stimulus controller wiring, dismiss button with aria-label |
| `test/system/cookie_notice_test.rb` | System test for show-once behaviour | VERIFIED | Exists, 27 lines, `CookieNoticeTest`, 2 tests: first-visit shows banner, dismiss hides and does not reappear |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| `app/views/layouts/application.html.erb` | `app/views/layouts/_cookie_notice.html.erb` | `render 'layouts/cookie_notice' if @show_cookie_notice` | WIRED | Line 117: confirmed |
| `app/views/layouts/_cookie_notice.html.erb` | `CookieNoticesController#dismiss` | `button_to cookie_notice_dismiss_path, method: :post` | WIRED | Line 10: `button_to cookie_notice_dismiss_path, method: :post` confirmed |
| `app/controllers/application_controller.rb` | `session[:cookie_notice_shown]` | `before_action :set_cookie_notice_flag` | WIRED | Line 22: `before_action :set_cookie_notice_flag`; private method at line 30 confirmed |

---

## Requirements Coverage

| Requirement | Status | Blocking Issue |
| ----------- | ------ | -------------- |
| ACC-01: GDPR right to erasure — user can permanently delete their account | SATISFIED | AccountsController#destroy + Current.user.destroy cascade |
| ACC-02: All associated health data deleted on account deletion | SATISFIED | User model has `dependent: :destroy` on symptom_logs, peak_flow_readings, personal_best_records, medications, dose_logs, health_events; `dependent: :delete_all` on sessions |
| LEGAL-01: Terms of Service page with UK GDPR-appropriate content | SATISFIED | 10-section Terms page, covers eligibility (16+), health data disclaimer, governing law England and Wales |
| LEGAL-02: Privacy Policy with UK GDPR + DPA 2018 compliance for health data app | SATISFIED | 10-section Privacy Policy, covers Art. 9 special category data, all 7 UK GDPR rights, ICO complaints route |
| LEGAL-03: Informational ePrivacy cookie notice for essential session cookies | SATISFIED | Dismissible banner shown once per session, PECR exemption stated, accessible, Stimulus-driven |

---

## Anti-Patterns Found

None. The single grep match for "placeholder" in `settings/show.html.erb` is a legitimate HTML `placeholder` attribute value on the confirmation text field — not a code stub.

---

## Security Findings

Brakeman scan: **0 warnings** across 21 controllers, 10 models, 71 templates.
bundler-audit: **No vulnerabilities found**.

| Check | Name | Severity | File | Line | Detail |
| ----- | ---- | -------- | ---- | ---- | ------ |
| — | — | — | — | — | No findings |

**Security:** 0 findings (0 critical, 0 high, 0 medium)

---

## Performance Findings

No performance concerns identified. Account deletion is a rare, single-record operation. Cookie notice is a simple session flag check on every request (negligible overhead). Legal pages are static ERB with no database queries.

**Performance:** 0 findings (0 high, 0 medium, 0 low)

---

## Human Verification Required

### 1. Cookie Notice Visual Appearance and Dismiss Animation

**Test:** Open the app in an incognito or private browser window (to have a fresh session). Observe the bottom of the viewport.
**Expected:** A banner appears at the bottom of the page containing "This site uses a session cookie to keep you signed in. No tracking or advertising cookies are used." with a link to Privacy Policy and an X button in the top-right of the banner.
**Why human:** CSS layout and visual positioning cannot be verified programmatically. The `bottom: 52px` mobile offset above the bottom nav also requires visual inspection on a narrow viewport.

### 2. Dismiss Animation and Session Persistence

**Test:** From the incognito window, click the X button on the cookie notice. Then navigate to another page.
**Expected:** The banner slides down and fades out (CSS transition), is removed from the DOM, and does not reappear on any subsequent page within the same session.
**Why human:** CSS transition animation (opacity/translateY) and the `transitionend` DOM removal require a live browser to observe.

### 3. Account Deletion Full Flow

**Test:** Sign in, go to Settings, scroll to Danger Zone. Type anything other than "DELETE" and submit. Then type "DELETE" exactly and submit.
**Expected:** Wrong confirmation — page reloads with alert, account intact. Correct confirmation — redirect to home page with notice, sign-in with original credentials fails.
**Why human:** End-to-end user flow with session reset and subsequent failed authentication is best confirmed manually to ensure no UI or session artifact persists post-deletion.

---

## Gaps Summary

No gaps. All 17 must-haves across the three plans are verified. All tests pass (7/7 controller tests). Security scan clean. No anti-patterns.

---

_Verified: 2026-03-10T14:55:14Z_
_Verifier: Claude (ariadna-verifier)_
