---
phase: 20-legal-pages-cookie-banner-error-pages
verified: 2026-03-12T18:37:44Z
status: passed
score: 14/14 must-haves verified | security: 0 critical, 0 high | performance: 0 high
---

# Phase 20: Legal Pages, Cookie Banner & Error Pages — Verification Report

**Phase Goal:** The app has publicly accessible Terms of Service, Privacy Policy, and Cookie Policy pages; a dismissible cookie consent banner shown on first visit; and custom 404, 500, and maintenance error pages that match the app's visual design.
**Verified:** 2026-03-12T18:37:44Z
**Status:** passed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| #  | Truth                                                                                                         | Status     | Evidence                                                                             |
|----|---------------------------------------------------------------------------------------------------------------|------------|--------------------------------------------------------------------------------------|
| 1  | GET /cookies returns 200 without authentication                                                               | VERIFIED   | Route `get "cookies", to: "pages#cookies"` in routes.rb; `allow_unauthenticated_access` on PagesController |
| 2  | Cookie Policy page contains realistic UK GDPR/PECR content — no lorem ipsum                                  | VERIFIED   | cookies.html.erb: both cookie names listed (`_asthma_buddy_session`, `cookie_notice_dismissed`), durations, purposes, ICO reference; no placeholders |
| 3  | All three legal pages render at max-width 680px via `.main--narrow`                                           | VERIFIED   | terms.html.erb, privacy.html.erb, and cookies.html.erb all wrap content in `<div class="main--narrow">`; legal.css defines `max-width: 680px` |
| 4  | Both footer variants in application.html.erb link to /terms, /privacy, and /cookies                          | VERIFIED   | Lines 133–135 (authenticated `.footer-app`) and lines 142–144 (public `<footer>`) both have all three `link_to` helpers |
| 5  | legal.css provides `.main--narrow`, `.legal-date`, and prose line-height styles                               | VERIFIED   | All three classes present in legal.css; all colour values use CSS custom properties (no hardcoded hex) |
| 6  | Dismissing the cookie notice sets a persistent cookie that survives session end                               | VERIFIED   | `CookieNoticesController#dismiss` sets `cookies[:cookie_notice_dismissed] = { value: "1", expires: 365.days.from_now }` |
| 7  | The cookie notice does not appear again after dismissal — even in a new browser session                       | VERIFIED   | Application layout checks `cookies[:cookie_notice_dismissed].present?` (persistent cookie, not session) |
| 8  | The cookie notice still appears on first visit before any dismissal                                           | VERIFIED   | Render condition: `unless authenticated? || cookies[:cookie_notice_dismissed].present?` — renders on first visit |
| 9  | The existing partial, CSS, and Stimulus controller are unchanged                                              | VERIFIED   | Plan 20-02 only modified `cookie_notices_controller.rb` and the layout condition |
| 10 | GET /404 renders the branded not-found page with HTTP status 404                                              | VERIFIED   | 5/5 errors_controller_test.rb tests pass; `render status: :not_found` in action |
| 11 | GET /500 renders the branded error page with HTTP status 500                                                  | VERIFIED   | Tests pass; `render status: :internal_server_error` in action |
| 12 | Both error pages show a large muted error code and a recovery link                                            | VERIFIED   | Both views have `.error-code` span and `.btn-primary` link; errors.css defines `clamp(4rem, 12vw, 8rem)` with `var(--brand-light)` |
| 13 | public/maintenance.html renders correctly without Rails — no external CSS or JS dependencies                  | VERIFIED   | 154-line standalone HTML file; 0 ERB/Rails/asset references; Plus Jakarta Sans from Google Fonts CDN; teal `#0d9488` inline |
| 14 | config.exceptions_app = self.routes routes real 404/500 exceptions to ErrorsController                       | VERIFIED   | Line 41 of config/application.rb: `config.exceptions_app = self.routes` |

**Score:** 14/14 truths verified

---

### Required Artifacts

| Artifact                                             | Expected                                       | Status     | Details                                                     |
|------------------------------------------------------|------------------------------------------------|------------|-------------------------------------------------------------|
| `app/views/pages/cookies.html.erb`                   | Cookie Policy page with UK GDPR/PECR content   | VERIFIED   | Contains `cookie_notice_dismissed`, both cookie names, ICO link, `main--narrow` wrapper |
| `app/assets/stylesheets/legal.css`                   | Narrow layout and prose typography             | VERIFIED   | Contains `.main--narrow`, `.legal-date`, line-height 1.75; no hardcoded hex |
| `app/controllers/pages_controller.rb`                | cookies action on PagesController              | VERIFIED   | `def cookies` action present; `allow_unauthenticated_access` covers all actions |
| `app/controllers/cookie_notices_controller.rb`       | Persistent cookie dismissal                    | VERIFIED   | Sets `cookies[:cookie_notice_dismissed]` with 365-day expiry |
| `app/views/layouts/application.html.erb`             | Conditional render + cookies links in footers  | VERIFIED   | Line 124: `cookies[:cookie_notice_dismissed].present?`; lines 135, 144: `cookies_path` in both footers |
| `app/controllers/errors_controller.rb`               | not_found and internal_server_error actions    | VERIFIED   | Both actions present; `allow_unauthenticated_access`; correct `render status:` calls |
| `app/views/errors/not_found.html.erb`                | Branded 404 view                               | VERIFIED   | Contains `.error-page`, `.error-code` "404", `h1 "Page not found"`, `.btn-primary` |
| `app/views/errors/internal_server_error.html.erb`    | Branded 500 view                               | VERIFIED   | Contains `.error-page`, `.error-code` "500", `h1 "Something went wrong"`, `.btn-primary` |
| `app/assets/stylesheets/errors.css`                  | Error page layout — large absolute error code  | VERIFIED   | Contains `.error-page`, `.error-code` with `clamp(4rem, 12vw, 8rem)`, all CSS custom properties |
| `public/maintenance.html`                            | Standalone maintenance page                    | VERIFIED   | 154 lines; Plus Jakarta Sans CDN; inline teal `#0d9488`; no ERB/Rails |
| `config/application.rb`                              | exceptions_app routing to self.routes          | VERIFIED   | `config.exceptions_app = self.routes` on line 41 |
| `test/controllers/errors_controller_test.rb`         | 5 controller tests                             | VERIFIED   | 5 tests, all pass (12 assertions, 0 failures) |

---

### Key Link Verification

| From                                    | To                                        | Via                                      | Status    | Details                                                          |
|-----------------------------------------|-------------------------------------------|------------------------------------------|-----------|------------------------------------------------------------------|
| `config/routes.rb`                      | `pages_controller.rb#cookies`             | `get "cookies", to: "pages#cookies"`     | WIRED     | Route present; action exists; `allow_unauthenticated_access`     |
| `app/views/layouts/application.html.erb` | `cookies_path`                           | `link_to "Cookies", cookies_path`        | WIRED     | Present in both authenticated (line 135) and public (line 144) footers |
| `app/views/pages/cookies.html.erb`      | `legal.css`                              | `.main--narrow` container class          | WIRED     | `<div class="main--narrow">` on line 4 of cookies.html.erb |
| `app/views/layouts/application.html.erb` | `cookie_notices_controller.rb#dismiss`  | `cookies[:cookie_notice_dismissed].present?` | WIRED | Line 124 checks persistent cookie; controller sets it with 365-day expiry |
| `config/routes.rb`                      | `errors_controller.rb#not_found`          | `match "/404", via: :all`                | WIRED     | Line 73 of routes.rb matches spec exactly                        |
| `config/application.rb`                 | `config/routes.rb`                        | `config.exceptions_app = self.routes`    | WIRED     | Line 41 of application.rb present                                |

---

### Requirements Coverage

| Requirement | Status    | Notes                                                    |
|-------------|-----------|----------------------------------------------------------|
| ERR-01 (branded 404) | SATISFIED | Branded not_found view, errors.css, correct HTTP status, tests pass |
| ERR-02 (branded 500) | SATISFIED | Branded internal_server_error view, correct HTTP status, tests pass |
| Legal pages (Terms, Privacy, Cookies) | SATISFIED | All three publicly accessible, narrow layout, realistic UK GDPR content |
| Cookie banner persistence | SATISFIED | 365-day persistent cookie replaces session-only flag |

---

### Anti-Patterns Found

None. No TODO/FIXME/HACK/placeholder comments found in any phase 20 files. No debug statements. No empty implementations (all actions are intentionally minimal — implicit render for legal pages, explicit status render for error pages).

---

### Security Findings

Brakeman scan: **0 warnings found** across 24 controllers, 11 models, 85 templates.
Bundler audit: **No vulnerabilities found.**

| Check | Name | Severity | Result |
|-------|------|----------|--------|
| 2.2a  | Strong params / mass assignment | — | Not applicable — no params accepted in any phase 20 controller |
| 3.1   | Unauthenticated access          | — | All phase 20 controllers use `allow_unauthenticated_access` correctly |
| 3.3b  | Cookie config                   | — | `cookies[:cookie_notice_dismissed]` sets value + expiry only; no sensitive data |

**Security:** 0 findings (0 critical, 0 high)

---

### Performance Findings

No performance concerns. Phase 20 controllers have no database queries. Legal and error page views are static renders with no N+1 risk.

**Performance:** 0 findings

---

### Human Verification Required

#### 1. Cookie banner first-visit appearance

**Test:** Open the app in an incognito window (or clear all localhost cookies). Visit the root path.
**Expected:** Cookie notice banner appears at the bottom of the screen.
**Why human:** Programmatic tests can't assert visual appearance of an in-browser DOM element rendered on first page load.

#### 2. Cookie banner persistent dismissal across sessions

**Test:** In incognito, dismiss the cookie banner. Reload the page. Close the tab, reopen and navigate to root.
**Expected:** The banner does not reappear after dismissal — not on reload, not in a new tab (same browser profile).
**Why human:** Session-vs-persistent cookie behaviour requires actual browser interaction to confirm.

#### 3. Visual design of error pages

**Test:** Visit /404 and /500 directly.
**Expected:** Large muted error code behind the content (positioned absolute), h1 headline, description paragraph, and a teal `.btn-primary` recovery button — matching the app's design system.
**Why human:** CSS positioning and visual stacking context cannot be verified programmatically.

#### 4. Legal pages narrow layout at mobile widths

**Test:** Visit /terms, /privacy, and /cookies. Resize browser to 375px viewport width.
**Expected:** Content is constrained to max-width 680px and readable at all viewport sizes.
**Why human:** Responsive CSS rendering requires a browser.

#### 5. maintenance.html standalone rendering

**Test:** Open `/path/to/public/maintenance.html` directly via `file://` in a browser.
**Expected:** Page renders with Plus Jakarta Sans heading, teal branding, centred layout — no broken styles, no blank page.
**Why human:** File-protocol rendering of Google Fonts CDN link requires a real browser to confirm CDN fallback behaviour.

---

## Summary

All 14 must-have truths are verified. Phase 20 delivered:

- Three publicly accessible legal pages at `/terms`, `/privacy`, `/cookies` — all using `.main--narrow` (680px) layout, realistic UK GDPR/PECR content, and `legal.css` prose typography with CSS custom properties only.
- Both authenticated and public footers link to all three legal pages.
- Cookie notice persistence upgraded from session-scoped to a 365-day persistent `cookies[:cookie_notice_dismissed]` cookie — banner correctly suppressed after dismissal, shown on first visit.
- Branded 404 and 500 error pages wired via `config.exceptions_app = self.routes`, with large muted error codes, `.btn-primary` recovery links, and `errors.css` using only CSS custom properties.
- Standalone `public/maintenance.html` with inline styles, Plus Jakarta Sans from Google Fonts CDN, and zero Rails dependencies.
- Full test suite passes: 500 tests, 0 failures. Brakeman: 0 warnings. Bundler audit: 0 vulnerabilities.

Five items require human browser verification (visual appearance, cookie behaviour, standalone file rendering) — none of these block the goal assessment.

---

_Verified: 2026-03-12T18:37:44Z_
_Verifier: Claude (ariadna-verifier)_
