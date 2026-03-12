# Phase 20 Context: Legal Pages, Cookie Banner & Error Pages

## Existing Codebase (what's already built)

**DO NOT REBUILD these — they already exist and work:**
- `PagesController` — has `terms` and `privacy` actions; `allow_unauthenticated_access`
- `app/views/pages/terms.html.erb` — full professional UK GDPR Terms of Service (10 sections, correct)
- `app/views/pages/privacy.html.erb` — full UK GDPR Privacy Policy (10 sections, mentions cookies in §8)
- `app/views/layouts/_cookie_notice.html.erb` — cookie notice banner (rendered in application layout)
- `app/javascript/controllers/cookie_notice_controller.js` — Stimulus: CSS transition dismiss, no persistent cookie
- `CookieNoticesController#dismiss` — sets `session[:cookie_notice_shown] = true`
- `config/routes.rb`: `post "cookie-notice/dismiss"`, `get "privacy"`, `get "terms"`, `as: :cookie_notice_dismiss`
- Application layout has both authenticated and unauthenticated footers, both include Privacy + Terms links

## Locked Decisions (honor exactly)

### Legal copy: write realistic content (no lorem ipsum)
User has no legal expertise. Write proper UK GDPR-compliant content for the Cookie Policy page. Style:
- Plain UK English (not American English)
- No placeholders — use `legal@asthmabuddy.app`, `privacy@asthmabuddy.app`, `Asthma Buddy` as the product name
- Match the voice, structure, and detail level of the existing terms.html.erb and privacy.html.erb

### Cookie notice: upgrade to persistent cookie on dismissal
The existing `CookieNoticesController#dismiss` uses `session[:cookie_notice_shown] = true` (session-only).
The comment in the controller acknowledges this is a "UX nuisance." Phase 20 should upgrade to a
persistent `cookies[:cookie_notice_dismissed]` (expires 365 days) so the notice never reappears after
first dismissal. Update the controller and the layout condition that controls rendering.

### ERR requirements: add to REQUIREMENTS.md
ERR-01 (branded 404) and ERR-02 (branded 500) are referenced in the roadmap but missing from
REQUIREMENTS.md. The planner should add them to REQUIREMENTS.md under a "Error Pages" section
before writing plans, so the requirement coverage tracking is accurate.

### Footer: already exists — no new footer partial needed
The application layout already has authenticated and public footers with Privacy + Terms links.
Do NOT create a `_footer.html.erb` partial. The `/cookies` link should be added to both footer
variants in `application.html.erb` alongside the existing Privacy and Terms links.

## Phase 20 Scope — What to Build

### Plan 20-01: Legal Pages & CSS
1. Add `cookies` action to existing `PagesController` (no new controller)
2. Add `get "cookies", to: "pages#cookies", as: :cookies` route
3. Create `app/views/pages/cookies.html.erb` — standalone Cookie Policy page with proper UK GDPR/PECR content:
   - What cookies are used (session cookie for authentication, `cookie_notice_dismissed` persistent dismissal cookie)
   - Duration, purpose, strictly-necessary classification
   - No analytics, no tracking, no advertising cookies
   - Contact details and ICO reference
4. Create `app/assets/stylesheets/legal.css` — narrow layout for all three legal pages:
   - `.main--narrow` modifier: `max-width: 680px; margin: 0 auto` (narrower than standard 860px)
   - `.legal-date` class: `color: var(--text-3); font-size: 0.875rem`
   - Prose styles: `line-height: 1.75`, good `h2` spacing, readable `ul`/`li` with left padding
5. Apply `main--narrow` container to existing `terms.html.erb` and `privacy.html.erb` views
6. Add `cookies` link to both footer variants in `app/views/layouts/application.html.erb`
7. Load `legal.css` in application layout (conditionally for legal pages via `yield(:stylesheets)` or unconditionally)

### Plan 20-02: Cookie Notice → Persistent Dismissal
The existing cookie notice infrastructure is mostly correct. Only the persistence needs upgrading.

1. Update `CookieNoticesController#dismiss`:
   - Set `cookies[:cookie_notice_dismissed] = { value: "1", expires: 365.days }` instead of session flag
   - Remove (or keep for safety) the session assignment
2. Update application layout condition:
   - Change `session[:cookie_notice_shown]` check to `cookies[:cookie_notice_dismissed].present?`
3. The existing `_cookie_notice.html.erb` partial, its CSS (`cookie_notice.css`), and the Stimulus
   controller (`cookie_notice_controller.js`) are all correct — do NOT rewrite them
4. No new partial, no new controller, no new Stimulus JS needed

### Plan 20-03: Branded Error Pages + Maintenance
1. Create `app/controllers/errors_controller.rb`:
   - `not_found` action (404)
   - `internal_server_error` action (500)
   - `allow_unauthenticated_access`
2. Add routes in `config/routes.rb`:
   - `match "/404", to: "errors#not_found", via: :all`
   - `match "/500", to: "errors#internal_server_error", via: :all`
3. Set `config.exceptions_app = self.routes` in `config/application.rb`
4. Create views:
   - `app/views/errors/not_found.html.erb` — "Page not found" with recovery link
   - `app/views/errors/internal_server_error.html.erb` — "Something went wrong" with recovery link
   - Design: large muted error code (`font-size: clamp(4rem, 12vw, 8rem); color: var(--brand-light)`)
     positioned absolute behind content; `.btn-primary` recovery action; headline in `--text`; description in `--text-3`
5. Create `app/assets/stylesheets/errors.css`
6. Create `public/maintenance.html` — fully self-contained (inline `<style>`, Plus Jakarta Sans from
   Google Fonts CDN, teal inline colours, no JavaScript, no Rails dependency)
7. Add controller tests for both error actions
8. Add `errors` stylesheet to application layout

## Design Rules (from DESIGN-SYSTEM.md / roadmap)
- Legal pages: `.section-card` at max-width 680px (narrower than standard 860px)
- Cookie banner: `position: fixed; bottom: 0; left: 0; right: 0; z-index: 200`; mobile `bottom: 52px` (above bottom nav)
- Error pages: large muted error code in `--font-heading`, `font-size: clamp(4rem, 12vw, 8rem)`, `color: var(--brand-light)`, positioned absolute behind content
- All CSS values use existing CSS variables — NO hardcoded colour values except maintenance page inline styles
- `--brand: var(--teal-600)` — use this for maintenance page inline teal

## Out of Scope
- No new cookie consent (consent is not required for strictly-necessary session cookies under UK PECR)
- No analytics integration, no cookie categories, no accept/reject buttons
- No redesign of existing Terms or Privacy content (content is correct and professional)
- No new footer partial (footer is already in application.html.erb)
