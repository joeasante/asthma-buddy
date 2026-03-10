# Roadmap: Asthma Buddy — Milestone 2

## Overview

Milestone 2 takes Asthma Buddy from a symptom and peak flow tracker to a full medication management and compliance tool. The eight phases move from the data foundations of medication modelling, through dose logging, stock tracking, and preventer adherence, into health event correlation, account control, legal compliance, and finally a guided onboarding experience for new users. When complete, a user can open the app, manage their inhalers, log doses, be warned before running out of medication, see whether they have taken their preventer today, correlate illness episodes with their peak flow chart, delete their account if they choose, and be legally protected to launch publicly.

**Product vision:** Users log consistently enough that patterns emerge — reducing asthma attacks and improving medication adherence.
**Building for:** Person with asthma who wants frictionless daily logging and is frustrated by forgetting to track or losing paper diaries.
**Milestone 2 theme:** Medication & Compliance

---

## Phases

**Phase Numbering:**
- Integer phases (10–17): Planned Milestone 2 work
- Decimal phases (e.g. 10.1): Urgent insertions if needed (marked INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 10: Medication Data Layer** — Medication and DoseLog models, validations, remaining-dose calculation
- [x] **Phase 11: Medication Management UI** — CRUD interface to add, edit, and remove medications from settings
- [x] **Phase 12: Dose Logging** (complete 2026-03-08) — Log a dose taken and delete accidental entries
- [x] **Phase 13: Dose Tracking & Low Stock** (complete 2026-03-08) — Remaining dose display, low-stock warning, refill action
- [x] **Phase 14: Adherence Dashboard** (complete 2026-03-10) — Today's preventer adherence indicator and 7/30-day history grid
- [x] **Phase 15: Health Events** — Log, edit, delete health events; show as chart markers on peak flow trends
- [ ] **Phase 16: Account Management & Legal** — Account deletion with confirmation; Terms, Privacy, cookie notice
- [ ] **Phase 17: Onboarding Flow** — Post-signup wizard prompting personal best and first medication
- [ ] **Phase 18: Temporary Medication Courses** — Record short-duration prescriptions (e.g. rescue steroids) with start/end date; auto-archive on expiry; excluded from adherence and low-stock tracking
- [ ] **Phase 19: Notifications** — In-app notification feed for low stock, missed doses, and peak flow reminders; unread badge on nav; mark read via Turbo Stream
- [ ] **Phase 20: Legal Pages & Cookie Banner** — Standalone Terms, Privacy, and Cookie Policy pages; dismissible cookie consent banner; error pages (404, 500, maintenance)

---

## Phase Details

### Phase 10: Medication Data Layer

**Goal**: The Medication and DoseLog data models exist with correct associations, validations, and the domain logic needed to calculate remaining doses and days of supply.
**Why this matters**: Every Milestone 2 feature — logging, tracking, adherence — operates on this data layer. A correct, well-tested foundation means no broken calculations surface to the user later.
**Depends on**: Milestone 1 complete (Phase 9 done; `Current.user` and User model in place)
**Requirements**: MED-01, MED-02, TRACK-01

**Success Criteria** (what must be TRUE):
  1. A Medication record can be created for a user with name, type (reliever / preventer / combination / other), standard_dose_puffs, starting_dose_count — and persisted without errors.
  2. A Medication record can optionally store sick_day_dose_puffs and doses_per_day (required only for preventers with a schedule).
  3. A DoseLog record associates a user, a medication, a puff count, and a recorded_at timestamp — and is rejected without all required fields.
  4. Calling `medication.remaining_doses` returns `starting_dose_count` minus the sum of all logged puffs for that medication.
  5. Calling `medication.days_of_supply_remaining` returns the remaining doses divided by the daily dose rate, rounded to one decimal place; returns nil when doses_per_day is blank.

**Plans**:
- [ ] 10-01: Medication migration, model, enum (reliever/preventer/combination/other), validations, belongs_to :user, fixtures, model tests
- [ ] 10-02: DoseLog migration, model, belongs_to :user + :medication, validations (puffs >= 1, recorded_at present), fixtures, model tests
- [ ] 10-03: `remaining_doses` and `days_of_supply_remaining` instance methods on Medication; `refilled_at` column; model tests for edge cases (no logs, refill resets count)

---

### Phase 11: Medication Management UI

**Goal**: An authenticated user can view their medication list, add a new medication, edit an existing one, and remove one they no longer use — all within the Settings section.
**Why this matters**: Before any dose can be logged, the user's inhalers must exist in the system. This phase gives users full control over their medication profile, which is the prerequisite for every downstream tracking feature.
**Depends on**: Phase 10
**Requirements**: MED-01, MED-02, MED-03

**Success Criteria** (what must be TRUE):
  1. A logged-in user can navigate to Settings, see a list of their medications (or an empty-state prompt), and add a new medication by completing a form with name, type, standard dose, and starting count — then see it appear in the list without a full page reload.
  2. Optional fields (sick-day dose, doses per day) are visible on the form and save correctly when filled in; they can be left blank.
  3. A user can open an existing medication, change any field, save, and see updated values reflected immediately.
  4. A user can delete a medication from their list and it is removed; a user cannot access another user's medications (cross-user isolation enforced).

**Plans**:
- [x] 11-01-PLAN.md — Settings::MedicationsController (6 CRUD actions) and /settings/medications routes
- [x] 11-02-PLAN.md — Medication views: index, card partial, form partial, Turbo Stream responses
- [x] 11-03-PLAN.md — Controller tests (CRUD + cross-user 404) and system tests (add, edit, remove)

---

### Phase 12: Dose Logging

**Goal**: A user can log a dose taken for any of their medications — specifying puffs and timestamp — and can delete an accidental or duplicate entry.
**Why this matters**: The dose log is the raw event record that powers remaining-dose calculations, low-stock warnings, and adherence tracking. Without it the medication profile is static and delivers no ongoing value.
**Depends on**: Phase 11
**Requirements**: DOSE-01, DOSE-02

**Success Criteria** (what must be TRUE):
  1. A logged-in user can log a dose taken for one of their medications — choosing the medication, entering puff count, and confirming the timestamp — and the entry appears in that medication's dose history.
  2. After logging a dose, the remaining dose count for that medication reflects the new total immediately.
  3. A user can delete a dose log entry they recorded and it is removed from the history; the remaining dose count updates accordingly.
  4. A user cannot log a dose against another user's medication (isolation enforced at controller level).

**Plans:** 3 plans
- [ ] 12-01-PLAN.md — Settings::DoseLogsController (create, destroy), nested routes under /settings/medications, scoped to Current.user; Turbo Stream responses
- [ ] 12-02-PLAN.md — Dose log form inline on medication card; dose history list (3-5 entries); remaining count display; Turbo Stream responses updating card on create/destroy
- [ ] 12-03-PLAN.md — Controller tests (create, destroy, cross-user isolation, auth) and system tests (log dose, delete dose, remaining count updates)

---

### Phase 13: Dose Tracking & Low Stock

**Goal**: Each medication card shows the remaining dose count; a low-stock warning appears when fewer than 14 days of supply remain; and a user can mark a medication as refilled to reset the count.
**Why this matters**: The worst outcome for a person with asthma is running out of their reliever. This phase turns the raw dose log into an active safety net — surfacing the warning early enough to request a prescription.
**Depends on**: Phase 12
**Requirements**: TRACK-01, TRACK-02, TRACK-03

**Success Criteria** (what must be TRUE):
  1. Every medication in the user's list displays a remaining dose count, and the number decreases as doses are logged.
  2. When remaining doses represent fewer than 14 days of supply (based on doses_per_day), a visually distinct low-stock warning appears on the medication card and on the dashboard.
  3. A user can trigger a refill action on a medication; the starting_dose_count resets to the new count and refilled_at is recorded — the low-stock warning disappears if the new count is sufficient.
  4. Medications with no doses_per_day schedule do not show days-of-supply or trigger the 14-day warning (no division by zero).

**Plans:** 3 plans
- [ ] 13-01-PLAN.md — LOW_STOCK_DAYS constant + low_stock? predicate on Medication model; days-of-supply text and low-stock badge on medication card; dashboard Medications section for low-stock medications
- [ ] 13-02-PLAN.md — Refill action: PATCH /settings/medications/:id/refill route, Settings::MedicationsController#refill updating starting_dose_count + refilled_at, details/summary inline form, Turbo Stream response
- [ ] 13-03-PLAN.md — Model tests for low_stock? (boundary, nil schedule); controller tests for refill (success, count=0, cross-user 404, unauthenticated); system tests (badge on card, badge clears after refill, dashboard section)

---

### Phase 14: Adherence Dashboard

**Goal**: The dashboard shows a preventer adherence indicator for today (doses taken vs scheduled), and a user can open a history view showing adherence for each preventer over the last 7 or 30 days.
**Why this matters**: Preventer inhalers only work when taken daily — missed doses are the single biggest controllable factor in avoidable asthma attacks. This phase makes adherence visible at a glance, which is the core medication compliance promise of Milestone 2.
**Depends on**: Phase 13
**Requirements**: ADH-01, ADH-02

**Success Criteria** (what must be TRUE):
  1. The dashboard displays an adherence card for each preventer medication showing doses logged today versus scheduled (e.g. "1 / 2 taken") with a clear visual distinction between on-track (all taken) and behind (fewer taken than scheduled).
  2. A preventer with no doses_per_day schedule does not appear in the adherence card (no misleading data shown).
  3. A user can navigate to an adherence history view and see a day-by-day grid for the last 7 days and last 30 days, where each day is colour-coded: green (all scheduled doses logged), red (fewer than scheduled), grey (no schedule or no data).
  4. The adherence history correctly handles days before the medication was added (shown as grey, not red).

**Plans:** 3 plans
- [ ] 14-01-PLAN.md — AdherenceCalculator service object (app/services/adherence_calculator.rb); TDD with unit tests covering on_track, missed, no_schedule, and pre-creation-date cases
- [ ] 14-02-PLAN.md — Dashboard adherence section: DashboardController loads @preventer_adherence; _adherence_card partial with N/N taken and on-track/missed colour states; adherence_path route
- [ ] 14-03-PLAN.md — AdherenceController (GET /adherence), history view with 7/30-day toggle, _history_grid partial with colour-coded cells; controller tests and system tests

---

### Phase 15: Health Events

**Goal**: A user can log a health event (illness episode, GP appointment, or prescription course) with a date and notes; they can edit or delete events; and health events appear as vertical markers on the peak flow trend chart.
**Why this matters**: Peak flow numbers alone don't explain why a chart dips — a logged illness or steroid course makes the correlation visible. This is what turns the chart from interesting to clinically useful for a GP conversation.
**Depends on**: Phase 14
**Requirements**: EVT-01, EVT-02, EVT-03

**Success Criteria** (called must be TRUE):
  1. A logged-in user can log a health event by selecting a type (illness episode / GP appointment / prescription course), entering a start date, optionally an end date, and optional notes — and the event appears in a health events history list.
  2. A user can edit any field of a health event and save the changes; they can delete an event and it is removed permanently.
  3. The peak flow trend chart displays a vertical line or marker at the date of each health event, visually distinguishable by event type; hovering or tapping the marker reveals the event type and date.
  4. A user cannot view, edit, or delete another user's health events (isolation enforced).

**Plans:** 3 plans
- [ ] 15-01-PLAN.md — HealthEvent fixtures, model unit tests (validations, helpers, scopes), controller integration tests (CRUD + auth + cross-user isolation)
- [ ] 15-02-PLAN.md — System tests: add/edit/delete event flows, point-in-time vs duration vs ongoing display, auth guard, cross-user URL isolation
- [ ] 15-03-PLAN.md — Chart marker canvas overlay: DashboardController assigns @health_event_markers JSON, dashboard canvas gets data attribute, chart_controller.js afterDraw plugin draws coloured vertical lines per event type, dashboard controller tests, system test confirming marker data wiring

---

### Phase 15.1: Reliever Usage History (INSERTED)

**Goal**: A user can view their reliever usage history — showing dose frequency over time with a 2×/week threshold indicator — and see how their reliever usage correlates with their peak flow trend.
**Why this matters**: Using a reliever more than twice a week is a clinical marker of poorly controlled asthma. This dedicated view surfaces that pattern clearly so the user has concrete evidence to discuss with their GP — turning raw dose logs into a meaningful safety signal.
**Depends on**: Phase 15
**Requirements**: REL-01, REL-02

**Success Criteria** (what must be TRUE):
  1. A logged-in user can navigate to the Reliever Usage page and see a daily breakdown of reliever puffs logged over the past 7 or 30 days, with a period toggle.
  2. Weeks where reliever usage exceeded 2 times are clearly highlighted, making it easy to spot poorly-controlled periods.
  3. The view includes a correlation view or summary showing reliever usage alongside peak flow readings over the same period.
  4. Only the current user's data is shown; a user cannot access another user's reliever usage history.

**Plans:** 3 plans
- [ ] 15.1-01-PLAN.md — Route, RelieverUsageController (inline weekly queries, GINA bands, correlation), index view (CSS bar chart, eyebrow pill, turbo-frame toggle, empty states), reliever_usage.css, dashboard link
- [ ] 15.1-02-PLAN.md — Controller integration tests and dose_log fixtures for weekly reliever patterns
- [ ] 15.1-03-PLAN.md — Gap closure: fix 12-week bar chart mobile overflow (scroll wrapper + min-width columns)

---

### Phase 16: Account Management & Legal

**Goal**: A user can permanently delete their account and all associated data; deletion requires typing "DELETE" as confirmation; and the app has publicly accessible Terms of Service, Privacy Policy, and a first-visit cookie notice.
**Why this matters**: Account deletion is a GDPR legal requirement — without it the app cannot launch publicly. The legal pages (Terms, Privacy Policy) and cookie notice are also required for public launch and build the trust that health data deserves.
**Depends on**: Phase 15
**Requirements**: ACC-01, ACC-02, LEGAL-01, LEGAL-02, LEGAL-03

**Success Criteria** (what must be TRUE):
  1. A logged-in user can navigate to account settings, initiate account deletion, and is presented with a confirmation step requiring them to type "DELETE" before the action proceeds.
  2. After confirmed deletion, the user's record and all dependent data (readings, logs, medications, dose logs, health events) are permanently erased; the user is redirected to the home page with a confirmation message and cannot log back in.
  3. `/terms` and `/privacy` pages are accessible without being logged in and are linked from the app footer on every page.
  4. A first-time visitor sees a dismissible cookie notice banner; once dismissed it does not reappear for that session (stored in the Rails session — no JavaScript cookie consent library required).

**Plans**:
- [ ] 16-01: Account deletion — `DELETE /account` route and AccountsController#destroy; User model `dependent: :destroy` audit across all associations; confirmation form requiring typed "DELETE"; redirect + flash on completion; controller tests
- [ ] 16-02: Static legal pages — TermsController and PrivacyController (or PagesController), `/terms` and `/privacy` routes accessible without authentication, ERB content for ToS and Privacy Policy (UK GDPR); footer partial with links
- [ ] 16-03: Session cookie notice — ApplicationController before_action sets `session[:cookie_notice_shown]`; dismissible banner partial rendered in layout when flag absent; dismiss action sets flag; system test for show-once behaviour

---

### Phase 17: Onboarding Flow

**Goal**: A user who has just signed up and has neither a personal best nor any medications is guided through a two-step onboarding wizard; each step can be skipped and completed later.
**Why this matters**: A new user who opens the app and sees an empty dashboard with no prompts finds no value and churns. The onboarding wizard closes the activation gap — it gets users to their first meaningful data point in the same session as signup.
**Depends on**: Phase 16
**Requirements**: ONBD-01, ONBD-02

**Success Criteria** (what must be TRUE):
  1. A user who signs up and has no personal best record and no medications is automatically shown the onboarding wizard after email verification and login.
  2. Step 1 prompts the user to set their personal best peak flow value using the existing personal best form; completing it advances to Step 2.
  3. Step 2 prompts the user to add their first medication using the existing medication form; completing it redirects to the dashboard.
  4. Each step has a visible skip link; skipping advances to the next step (or to the dashboard if skipping Step 2); a skipped step does not re-appear on subsequent logins once either step has been completed or explicitly skipped in that session.
  5. A returning user who already has a personal best and at least one medication is never shown the onboarding wizard.

**Plans**:
- [ ] 17-01: OnboardingController with steps (:personal_best, :medication); before_action guard redirects to dashboard if user already has personal best and medication; step routing logic
- [ ] 17-02: Onboarding views — Step 1 (personal best form, skip link), Step 2 (medication form, skip link), progress indicator; reuse existing form partials
- [ ] 17-03: After-login redirect hook — check onboarding conditions in SessionsController or ApplicationController after_sign_in; system tests for full wizard completion, skip step 1, skip step 2, skip both, returning user bypass

---

## Progress

**Execution Order:**
Phases execute in numeric order: 10 -> 11 -> 12 -> 13 -> 14 -> 15 -> 16 -> 17 -> 18 -> 19 -> 20

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 10. Medication Data Layer | 3/3 | Complete ✓ | 2026-03-08 |
| 11. Medication Management UI | 3/3 | Complete ✓ | 2026-03-08 |
| 12. Dose Logging | 3/3 | Complete ✓ | 2026-03-08 |
| 13. Dose Tracking & Low Stock | 3/3 | Complete ✓ | 2026-03-08 |
| 14. Adherence Dashboard | 3/3 | Complete ✓ | 2026-03-10 |
| 15. Health Events | 3/3 | Complete ✓ | 2026-03-09 |
| 15.1. Reliever Usage History | 0/2 | Not started | - |
| 16. Account Management & Legal | 0/3 | Not started | - |
| 17. Onboarding Flow | 0/3 | Not started | - |
| 18. Temporary Medication Courses | 0/3 | Not started | - |
| 19. Notifications | 0/3 | Not started | - |
| 20. Legal Pages & Cookie Banner | 0/3 | Not started | - |

---

## Requirement Coverage

**Milestone 2 — 20 requirements — 20 mapped — 0 unmapped**

| Requirement | Phase |
|-------------|-------|
| MED-01 | Phase 10, Phase 11 |
| MED-02 | Phase 10, Phase 11 |
| MED-03 | Phase 11 |
| DOSE-01 | Phase 12 |
| DOSE-02 | Phase 12 |
| TRACK-01 | Phase 10, Phase 13 |
| TRACK-02 | Phase 13 |
| TRACK-03 | Phase 13 |
| ADH-01 | Phase 14 |
| ADH-02 | Phase 14 |
| EVT-01 | Phase 15 |
| EVT-02 | Phase 15 |
| EVT-03 | Phase 15 |
| ACC-01 | Phase 16 |
| ACC-02 | Phase 16 |
| LEGAL-01 | Phase 16 |
| LEGAL-02 | Phase 16 |
| LEGAL-03 | Phase 16 |
| ONBD-01 | Phase 17 |
| ONBD-02 | Phase 17 |

---

*Roadmap created: 2026-03-08 — Milestone 2*
*Milestone 1 (Phases 1–9) archived — all 9 phases complete*

### Phase 18: Temporary Medication Courses

**Goal**: A user can record a short-duration prescription (e.g. a rescue prednisolone course) as a temporary medication with a start date, end date, prescribed dose, and total unit count. Once the end date passes the course auto-archives and is excluded from adherence tracking, low-stock alerts, and the "Preventers Today" dashboard section.
**Why this matters**: Rescue steroid courses are a standard part of asthma management but don't fit the ongoing-medication model. Without this, users either skip recording them (losing medically important history) or pollute their active medication list with expired courses.
**Depends on**: Phase 15 (Health Events), Phase 17 (Onboarding)
**Requirements**: COURSE-01, COURSE-02, COURSE-03

**Design rules (DESIGN-SYSTEM.md is the single source of truth):**
- All colours via CSS custom property — no raw hex values outside :root
- Spacing tokens only (--space-xs through --space-2xl) — no px except 1px/2px borders
- Typography: --font-heading / --font-body, base 1.125rem, match type scale in DESIGN-SYSTEM.md §1.2
- Touch targets 44px minimum on `pointer: coarse` devices
- Reuse existing components: .section-card, .btn-primary, .field, .field-error, .medication-badge
- Form: label above input, .field-error below input, focus ring `var(--brand-ring)`, min input height 44px
- Every destructive action through the `<dialog>` confirm modal via confirm_controller.js — never fire DELETE on direct click
- Turbo Stream responses for all mutations; `toast:show` CustomEvent for success feedback
- Stimulus controllers for interactive behaviour (course toggle, date fields) — no inline JS in ERB
- Mobile-first: works at 375px (bottom nav), 768px, 1280px (top nav)
- Preflight checklist: all colours CSS vars, spacing tokens, 44px touch targets, hover/focus/active/disabled states on every interactive element, empty state with icon+headline+description+CTA, prefers-reduced-motion overrides

**Success Criteria** (what must be TRUE):
  1. A user can add a medication and mark it as a temporary course, entering a start date, end date, prescribed dose, and total unit count — distinct from the ongoing preventer/reliever form fields.
  2. An active course (end date in the future or today) appears in the medication list clearly labelled as a course with its end date shown; it does not appear in "Preventers Today" or trigger low-stock alerts.
  3. Once a course's end date has passed, it is automatically treated as archived — it disappears from the active list and moves to a "Past courses" section, which is collapsible and empty-stated.
  4. Dose logging for a course works identically to regular medications; remaining units count down as doses are logged.
  5. A user cannot interact with another user's course medications (isolation enforced).

**Plans**:
- [ ] 18-01: Medication model — add `course` boolean (default false), `starts_on` date, `ends_on` date; `active` and `archived` scopes; validations (ends_on after starts_on when course); update AdherenceCalculator and low_stock? to exclude active courses; model tests
- [ ] 18-02: Medication form — "This is a temporary course" checkbox (Stimulus controller shows/hides course date fields and hides doses_per_day); controller permits new params; index page splits active vs archived with collapsible "Past courses" section; Turbo Stream responses; CSS
- [ ] 18-03: Controller tests (create course, archive boundary, cross-user isolation) and system tests (add course, verify excluded from adherence, verify archived after end date, dose logging on course)

---

### Phase 19: Notifications

**Goal**: Users receive in-app notifications for actionable events — low medication stock, missed preventer doses, and peak flow reminders. A notification feed at `/notifications` lists all notifications newest-first; unread notifications show a badge count on the nav bell icon; individual and bulk mark-as-read via Turbo Stream.
**Why this matters**: Passive tracking only works if the app surfaces the moments that require action. Without notifications, a user must remember to check their stock and adherence themselves — defeating the compliance purpose of the medication tracking features.
**Depends on**: Phase 18
**Requirements**: NOTIF-01, NOTIF-02, NOTIF-03

**Design rules (DESIGN-SYSTEM.md is the single source of truth):**
- All colours via CSS custom property — no raw hex values outside :root
- Notification type colours: low stock `--severity-moderate-text`, missed dose `--severity-severe`, peak flow reminder `--brand`, system/general `--text-3`
- Unread row background `--brand-light`; read row background `--surface`
- Unread dot: 6px circle, `background: var(--brand)`
- Unread nav badge: 8px red circle as CSS `::after` pseudo-element on the bell icon button; defined via `data-unread-count` attribute
- Spacing tokens only — no px except borders
- Touch targets 44px minimum
- Reuse .section-card, .page-header, .empty-state, .btn-secondary
- Every row is a link — full 44px min-height tap target
- Turbo Stream for mark-read (single row) and mark-all-read (all rows + badge update)
- Relative timestamps via `relative_time_controller.js` Stimulus controller updating every 60 seconds
- Mobile-first; bottom nav tab decision: replace Profile tab with Notifications; Profile accessible via avatar dropdown (already present on desktop)
- Preflight: colours CSS vars, touch targets, hover/focus/active states, empty state ("You're all caught up."), reduced-motion overrides

**Success Criteria** (what must be TRUE):
  1. A notification is created automatically when a medication falls below the low-stock threshold, when a scheduled preventer dose is missed by end of day, or when triggered by a system event.
  2. The `/notifications` feed lists all notifications for the current user, newest first, with type icon, body text (bold if unread), relative timestamp, and an unread indicator dot.
  3. Clicking a notification row marks it as read (Turbo Stream updates that row inline) and navigates to the relevant record.
  4. "Mark all read" updates all rows simultaneously via Turbo Stream and removes the nav badge.
  5. The nav bell icon shows an unread count badge when there are unread notifications; the badge disappears when count reaches zero.
  6. The empty state ("You're all caught up.") displays when all notifications are read or none exist.

**Plans**:
- [ ] 19-01: Notification model — user association, `notification_type` enum (low_stock/missed_dose/peak_flow_reminder/system), `read` boolean (default false), `body` string, `target_path` string, `created_at`; `unread` scope; migration; model tests; background job or ActiveSupport::Notifications hook to create low-stock notifications
- [ ] 19-02: NotificationsController (index, update for mark-read, `mark_all_read` action); routes; `_notification.html.erb` partial; `mark_read.turbo_stream.erb`; `mark_all_read.turbo_stream.erb`; `notifications.css`; `relative_time_controller.js`; nav bell icon with unread badge via layout change
- [ ] 19-03: Controller tests (index, mark read, mark all read, cross-user isolation) and system tests (badge appears, mark single read, mark all read, empty state)

---

### Phase 20: Legal Pages, Cookie Banner & Error Pages

**Goal**: The app has publicly accessible Terms of Service, Privacy Policy, and Cookie Policy pages; a dismissible cookie consent banner shown on first visit; and custom 404, 500, and maintenance error pages that match the app's visual design.
**Why this matters**: These are non-negotiable requirements for public launch — GDPR mandates accessible privacy and deletion rights documentation, the cookie banner satisfies ePrivacy Directive obligations, and branded error pages prevent users from seeing a broken Rails default during incidents.
**Depends on**: Phase 19
**Requirements**: LEGAL-01, LEGAL-02, LEGAL-03, ERR-01, ERR-02

**Design rules (DESIGN-SYSTEM.md is the single source of truth):**
- Legal pages: single .section-card at max-width 680px (narrower than standard 860px); plain prose layout (`<h2>` section titles, `<p>`, `<ul>`); `<p class="legal-date">` in `--text-3`, 0.875rem
- Cookie banner: `position: fixed; bottom: 0; left: 0; right: 0; z-index: 200`; on mobile `bottom: 52px` (above bottom nav); background `--surface`; `border-top: 1px solid var(--border)`; `box-shadow: 0 -2px 8px rgba(0,0,0,0.06)`; flex row (desktop) → stacked column (mobile)
- Error pages (404/500): large muted error code number in `--font-heading`, `font-size: clamp(4rem, 12vw, 8rem)`, `color: var(--brand-light)`, positioned absolute behind content; headline in `--text`; description in `--text-3`; .btn-primary action link
- Maintenance page (`public/maintenance.html`): fully self-contained HTML with inline `<style>`; Plus Jakarta Sans from Google Fonts CDN; teal brand colour inline; no JavaScript; no Rails layout dependency
- All colours CSS vars except maintenance page inline styles and :root definitions
- Preflight: colours CSS vars, spacing tokens, touch targets, hover/focus/active states, reduced-motion overrides, no lorem ipsum (realistic UK GDPR-appropriate legal copy)

**Success Criteria** (what must be TRUE):
  1. `/terms`, `/privacy`, and `/cookies` are accessible without authentication and render correctly at 375px, 768px, and 1280px with appropriate legal content (no lorem ipsum).
  2. A first-time visitor sees the cookie consent banner; dismissing it sets a session flag and the banner never reappears in that session or on return visits (persistent cookie).
  3. A `404` response renders the branded not-found page with a link to the dashboard (or home if unauthenticated); a `500` renders the branded error page.
  4. `public/maintenance.html` is a standalone file that renders correctly without Rails, showing the Asthma Buddy name and maintenance message.
  5. Footer on every page links to `/terms` and `/privacy`.

**Plans**:
- [ ] 20-01: PagesController (`terms`, `privacy`, `cookies` actions, no auth); routes; ERB content (UK GDPR-appropriate); `legal.css`; footer partial with links rendered in application layout; `main--narrow` modifier for 680px content width
- [ ] 20-02: Cookie consent banner — `_cookie_banner.html.erb` partial; `cookie_banner_controller.js` Stimulus controller (sets persistent cookie, CSS transition to hide); ApplicationController `before_action` sets `@show_cookie_banner`; `cookie_banner.css`
- [ ] 20-03: Error pages — ErrorsController (`not_found`, `internal_server_error`); routes (`match '/404'`, `match '/500'`); `config.exceptions_app = self.routes` in application.rb; `errors.css`; `public/maintenance.html` standalone file; controller tests

---
