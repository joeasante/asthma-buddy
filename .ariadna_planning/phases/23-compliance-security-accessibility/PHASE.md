# Phase 23: Compliance, Security & Accessibility

**Status:** Planned
**Created:** 2026-03-13
**Depends on:** Phase 22 (Request-Path Caching) — Complete

---

## Goal

Before any further features ship, the app must meet its non-negotiable legal and security baseline. This phase delivers:

1. **Security hardening** — rate limiting on auth endpoints (rack-attack) and idle session timeout.
2. **WCAG 2.2 accessibility** — colour-not-alone fixes, keyboard focus not obscured by the fixed bottom nav, chart accessible fallbacks.
3. **GDPR compliance** — data export (Art. 20 right to portability), medical device disclaimer, data retention statement in Privacy Policy, and an internal breach notification procedure.

## Why This Matters

The app is live with real users and stores **special category health data (UK GDPR Art. 9)**. The three deficits addressed here are not backlog items — they are legal obligations or security hygiene that should have been in place at launch:

- **No rate limiting** means the login endpoint is open to credential stuffing attacks. A few thousand requests per second would expose user health data.
- **No session timeout** means a shared or borrowed device leaves a user's health data permanently accessible.
- **No data export** means the app is non-compliant with UK GDPR Art. 20 today. Any user can formally request their data; without this feature the obligation must be fulfilled manually.
- **Colour-only zone indicators** fail WCAG 2.2 SC 1.4.1 — users with colour blindness (8% of males) cannot distinguish Green/Yellow/Red zones without the text that is already present in some but not all contexts.

## WCAG 2.2 vs 2.1 — What Changes

This phase targets **WCAG 2.2 Level AA**, not the superseded 2.1. Key new criteria in 2.2 that apply to this app:

| Criterion | Level | Relevance |
|-----------|-------|-----------|
| **2.4.11 Focus Not Obscured (Minimum)** | AA | Fixed bottom nav (`position: fixed`) can completely hide a focused element when the user tabs near the bottom of the page. The focused component must not be *entirely* hidden. |
| **2.4.12 Focus Not Obscured (Enhanced)** | AAA | Focused component is *fully* visible. Worth targeting but not required for AA. |
| **2.5.8 Target Size (Minimum)** | AA | Interactive targets must be at least 24×24 CSS pixels (or have 24px spacing). We already target 44px (`pointer: coarse`) — verify small controls like filter pills and notification dismiss don't fall below 24px on desktop. |
| **3.2.6 Consistent Help** | A | Help mechanisms must appear in the same location across pages. Not currently applicable (no help UI). |

Pre-existing criteria that remain relevant in 2.2:
- **1.4.1 Use of Colour** (A) — colour cannot be the *only* visual means of conveying information. Zone colours need a non-colour differentiator in every context they appear.
- **2.4.7 Focus Visible** (AA) — focus ring must be visible. Verify `var(--brand-ring)` is not suppressed on any interactive element.
- **4.1.2 Name, Role, Value** (A) — interactive components need accessible names. Verify icon-only buttons have `aria-label`.

---

## Success Criteria

1. `POST /session` and `POST /registrations` are rate-limited; a bot making 20+ rapid login attempts receives a 429 response.
2. A user whose session has been idle for more than 60 minutes is redirected to login on their next request, with a clear "session expired" message.
3. Zone colour indicators (pills, chart legend, dashboard stat values) all include a text label alongside the colour — a user with deuteranopia can identify zones without relying on colour alone.
4. Keyboard focus is never entirely obscured by the bottom nav when tabbing through the page on mobile viewport width.
5. Each chart canvas has a visually hidden summary paragraph that screen readers announce instead of "chart".
6. A logged-in user can navigate to `/account/export` and receive a JSON file containing all their stored health data.
7. Every page footer and the Terms page include a medical device disclaimer.
8. The Privacy Policy states the data retention policy (data deleted immediately and permanently on account deletion).
9. An internal `SECURITY.md` documents the breach notification procedure (who to notify, what to say to ICO, 72-hour window).

---

## Plans

### Plan 23-01: Security Hardening — Rate Limiting & Session Timeout

**Goal:** Lock down the two most exposed attack surfaces: brute-force login and persistent abandoned sessions.

#### A. Rate Limiting (rack-attack)

1. **Add gem** — `gem "rack-attack"` to Gemfile. Run `bundle install`.

2. **Create `config/initializers/rack_attack.rb`**:
   ```ruby
   class Rack::Attack
     # Throttle login attempts: 5 per IP per 20 seconds
     throttle("logins/ip", limit: 5, period: 20) do |req|
       req.ip if req.path == "/session" && req.post?
     end

     # Throttle signup attempts: 3 per IP per hour
     throttle("signups/ip", limit: 3, period: 1.hour) do |req|
       req.ip if req.path == "/registrations" && req.post?
     end

     # Custom response for throttled requests
     self.throttled_responder = lambda do |_env|
       [429, { "Content-Type" => "text/plain" }, ["Too many requests. Please wait before trying again."]]
     end
   end
   ```

3. **Enable in middleware** — add `config.middleware.use Rack::Attack` to `config/application.rb` (or verify it auto-inserts via Railtie).

4. **Tests** — integration test: 6 rapid POST /session requests from same IP; assert 6th returns 429.

#### B. Idle Session Timeout

1. **`ApplicationController` before_action** — add `before_action :check_session_freshness` after existing auth before_actions:
   ```ruby
   IDLE_TIMEOUT = 60.minutes

   def check_session_freshness
     return unless session[:last_seen_at]
     if Time.current - session[:last_seen_at].to_time > IDLE_TIMEOUT
       reset_session
       redirect_to new_session_path, alert: "Your session expired due to inactivity. Please sign in again."
     else
       session[:last_seen_at] = Time.current
     end
   end
   ```

2. **`SessionsController#create`** — set `session[:last_seen_at] = Time.current` after successful login.

3. **Skip on unauthenticated paths** — `skip_before_action :check_session_freshness` on `SessionsController`, `RegistrationsController`, `PasswordsController`, `EmailVerificationsController`, and `PagesController`.

4. **Tests** — integration test: session with `last_seen_at` 61 minutes ago redirects to login; session with `last_seen_at` 59 minutes ago passes through; `last_seen_at` updated on each request.

**Files touched:** `Gemfile`, `Gemfile.lock`, `config/application.rb`, `config/initializers/rack_attack.rb`, `app/controllers/application_controller.rb`, `app/controllers/sessions_controller.rb`, `test/integration/rate_limiting_test.rb`, `test/integration/session_timeout_test.rb`

---

### Plan 23-02: WCAG 2.2 Accessibility Fixes

**Goal:** Colour-not-alone (SC 1.4.1), focus not obscured by bottom nav (SC 2.4.11), chart accessible text fallbacks (SC 4.1.2 + 1.1.1), target size audit (SC 2.5.8).

#### A. Colour-Not-Alone (SC 1.4.1)

The following UI contexts currently use colour as the only differentiator and must be fixed:

1. **Dashboard "Avg this week" stat value** — renders as a zone-coloured number (e.g. `dash-stat-value--zone-green`). Add a visually-hidden zone label:
   ```erb
   <span class="dash-stat-value dash-stat-value--zone-<%= @week_avg_zone %>">
     <%= @week_avg %><span class="dash-stat-unit"> L/min</span>
     <span class="visually-hidden">(<%= @week_avg_zone&.capitalize %> zone)</span>
   </span>
   ```

2. **Peak flow zone pills on reading cards** — verify the zone text ("Green", "Yellow", "Red") is present as visible text, not just colour. If any context shows a coloured dot with no text label, add the label.

3. **Chart legend items** — `dash-zone-legend-item--green/yellow/red` use background colour. Add a `::before` symbol differentiator in CSS (▲ green, ◆ yellow, ✕ red), OR ensure the text "Green", "Yellow", "Red" has sufficient contrast independently. Text label is already present — verify it has visible contrast at ≥3:1 against the background regardless of the colour swatch.

4. **Severity badges** (`severity-badge--mild/moderate/severe`) — verify the text "Mild"/"Moderate"/"Severe" is present alongside the colour. CSS `text-transform: uppercase` is fine as long as the text is in the DOM.

5. **Add `.visually-hidden` CSS utility** to `application.css` if not present:
   ```css
   .visually-hidden {
     position: absolute;
     width: 1px;
     height: 1px;
     padding: 0;
     margin: -1px;
     overflow: hidden;
     clip: rect(0, 0, 0, 0);
     white-space: nowrap;
     border: 0;
   }
   ```

#### B. Focus Not Obscured by Bottom Nav (SC 2.4.11, new in WCAG 2.2)

The bottom nav is `position: fixed` at the bottom of the viewport. When a user tabs to the last interactive element above the bottom nav, the element could be fully hidden behind it.

Fix in the stylesheet that controls bottom nav layout (likely `application.css` or a layout CSS file):
```css
/* Ensure the last focusable element above the bottom nav is never fully obscured */
@media (max-width: 767px) {
  main, .main {
    padding-bottom: calc(var(--bottom-nav-height, 56px) + var(--space-lg));
  }
}
```

This pads the main content area so the last focusable item scrolls into view above the nav. Verify with keyboard navigation at 375px viewport width.

#### C. Chart Accessible Fallbacks (SC 4.1.2, 1.1.1)

Canvas elements convey visual data to sighted users but are opaque to screen readers. Each chart needs a text alternative.

For each chart canvas, add a visually-hidden summary inside the canvas element:
```erb
<canvas class="chart-canvas" aria-label="Peak flow readings over the last 7 days" role="img">
  <p class="visually-hidden">
    Peak flow chart for the week of <%= Date.current.beginning_of_week.strftime("%-d %b") %>:
    <%= @chart_data.map { |d| "#{d[:date]}: #{[d[:morning], d[:evening]].compact.join(" / ")} L/min" }.join(". ") %>.
  </p>
</canvas>
```

Apply to: dashboard chart, peak flow index chart, symptoms chart. Symptom chart summary should describe the severity distribution, not raw data.

#### D. Target Size Audit (SC 2.5.8)

Minimum 24×24 CSS pixels for all interactive targets (with a 24px spacing offset alternative allowed). Visually inspect:
- Filter pills on peak flow/symptom pages — if `min-height` is below 24px on desktop, fix to `min-height: 24px`
- Notification dismiss/action buttons
- Pagination prev/next buttons

Add to `application.css` rule comment: "WCAG 2.2 SC 2.5.8 — all interactive elements minimum 24×24px."

**Files touched:** `app/views/dashboard/index.html.erb`, `app/views/peak_flow_readings/index.html.erb`, `app/views/symptom_logs/index.html.erb`, `app/assets/stylesheets/application.css`, `app/assets/stylesheets/charts.css`, relevant feature CSS files.

---

### Plan 23-03: GDPR Compliance — Data Export, Disclaimer & Policies

**Goal:** Data export for right to portability (Art. 20); medical device disclaimer; data retention statement in Privacy Policy; breach notification procedure in SECURITY.md.

#### A. Data Export — Right to Portability (UK GDPR Art. 20)

1. **Route** — add to `config/routes.rb` inside the authenticated section:
   ```ruby
   get "/account/export", to: "accounts#export", as: :account_export
   ```

2. **AccountsController#export** — stream a JSON file:
   ```ruby
   def export
     user = Current.user
     data = {
       exported_at: Time.current.iso8601,
       user: {
         email: user.email_address,
         name: user.name,
         joined: user.created_at.iso8601
       },
       peak_flow_readings: user.peak_flow_readings.order(:recorded_at)
         .as_json(only: %i[value zone time_of_day recorded_at]),
       symptom_logs: user.symptom_logs.order(:recorded_at)
         .as_json(only: %i[symptom_type severity recorded_at]),
       medications: user.medications
         .as_json(only: %i[name medication_type standard_dose_puffs doses_per_day starting_dose_count created_at]),
       dose_logs: user.dose_logs.order(:recorded_at)
         .as_json(only: %i[puffs recorded_at]),
       health_events: user.health_events.order(:recorded_at)
         .as_json(only: %i[event_type recorded_at ended_at])
     }
     send_data data.to_json,
       filename: "asthma-buddy-data-#{Date.current}.json",
       type:     "application/json",
       disposition: "attachment"
   end
   ```

3. **Settings link** — add "Download your data" link in Settings (`app/views/settings/show.html.erb`) in the account section, visible to all authenticated users. Include a short description: "Download a copy of all your health data as a JSON file."

4. **Tests** — controller test: response is 200 with `application/json` content type; JSON includes user's own readings; does not include another user's data; unauthenticated redirects to login.

#### B. Medical Device Disclaimer

UK MDR 2002 (as amended) and EU MDR 2017 require that software intended for medical purposes is registered as a medical device. A personal tracking diary with no diagnostic claims is typically exempt, but only if this is made explicit.

1. **Footer** — add disclaimer text to both footer instances in `app/views/layouts/application.html.erb`:
   ```erb
   <p class="footer-disclaimer">Asthma Buddy is a personal tracking tool, not a medical device. Always consult your doctor or healthcare professional for medical advice.</p>
   ```

2. **Terms of Service** — add a section "Medical Disclaimer" to `app/views/pages/terms.html.erb`:
   > Asthma Buddy is a personal health tracking tool. It is not a medical device and does not provide medical advice, diagnosis, or treatment. Data and trends shown in the app are for personal reference only. Always seek the advice of a qualified healthcare professional regarding any medical condition.

3. **CSS** — add `.footer-disclaimer` styling: `font-size: 0.75rem; color: var(--text-3); max-width: 42ch;` — small, muted, not competing with the legal nav links.

#### C. Data Retention Policy

Update `app/views/pages/privacy.html.erb` to add an explicit data retention section:

> **Data Retention**
>
> We retain your personal data and health records for as long as your account is active. When you delete your account, all personal data including peak flow readings, symptom logs, dose records, medication details, and health events are permanently and immediately deleted from our systems. There is no grace period or soft-delete — deletion is irreversible.
>
> Backups: production database backups are retained for [N] days before automatic deletion. Your data may exist in a backup for up to [N] days after account deletion, after which it is permanently removed.

Note: fill in the backup retention period based on your actual Litestream/backup configuration before publishing.

#### D. Breach Notification Procedure (GDPR Art. 33)

Create `SECURITY.md` at the project root documenting the internal procedure. This does not need to be published publicly — it is for the developer's own reference:

```markdown
# Security & Breach Response

## Reporting a Vulnerability
If you discover a security vulnerability, email [your email] directly.

## Breach Notification Procedure (UK GDPR Art. 33)

### What constitutes a notifiable breach
A personal data breach must be reported to the ICO if it is likely to result in a risk to individuals' rights and freedoms. For Asthma Buddy, this includes: unauthorised access to the database, credential exposure, or data loss affecting user health records.

### Timeline
- **Within 1 hour**: Assess severity. Take the app offline if data is actively being accessed by an unauthorised party.
- **Within 24 hours**: Identify the scope (which users affected, what data type, what period).
- **Within 72 hours**: Report to ICO at https://ico.org.uk/for-organisations/report-a-breach/ if the breach is notifiable.
- **Without undue delay**: Notify affected users if the breach is likely to result in high risk to them.

### ICO notification contents (Art. 33(3))
1. Nature of the breach (accidental/unauthorised access/loss)
2. Categories and approximate number of individuals affected
3. Categories and approximate number of records affected
4. Name and contact details of DPO (or developer contact)
5. Likely consequences of the breach
6. Measures taken or proposed to address the breach

### ICO contact
- Report online: https://ico.org.uk/for-organisations/report-a-breach/
- Phone: 0303 123 1113
```

**Files touched:** `config/routes.rb`, `app/controllers/accounts_controller.rb`, `app/views/settings/show.html.erb`, `app/views/layouts/application.html.erb`, `app/views/pages/terms.html.erb`, `app/views/pages/privacy.html.erb`, `app/assets/stylesheets/application.css`, `SECURITY.md`, `test/controllers/accounts_controller_test.rb`

---

## Previously Completed (This Session, 2026-03-13)

**Dashboard query fixes (applied directly, not a plan):**
- `@recent_symptoms` week-scoped: was unbounded (any 4 symptoms); now `in_date_range(week_start, nil)`.
- `@recent_health_events` context-scoped: was any 3 recent events; now ongoing duration events + events in last 14 days (POINT_IN_TIME_TYPES excluded from ongoing catch-all).

**Layout reorders (previously applied in working tree):**
- Peak Flow page: chart moved before filter bar.
- Symptoms page: chart moved before filter bar.
