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

- [ ] **Phase 10: Medication Data Layer** — Medication and DoseLog models, validations, remaining-dose calculation
- [ ] **Phase 11: Medication Management UI** — CRUD interface to add, edit, and remove medications from settings
- [ ] **Phase 12: Dose Logging** — Log a dose taken and delete accidental entries
- [ ] **Phase 13: Dose Tracking & Low Stock** — Remaining dose display, low-stock warning, refill action
- [ ] **Phase 14: Adherence Dashboard** — Today's preventer adherence indicator and 7/30-day history grid
- [ ] **Phase 15: Health Events** — Log, edit, delete health events; show as chart markers on peak flow trends
- [ ] **Phase 16: Account Management & Legal** — Account deletion with confirmation; Terms, Privacy, cookie notice
- [ ] **Phase 17: Onboarding Flow** — Post-signup wizard prompting personal best and first medication

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
- [ ] 11-01: MedicationsController (index, new, create, edit, update, destroy), routes (`resources :medications` under /settings or top-level), scoped to Current.user
- [ ] 11-02: Views — medications index (list + empty state), new/edit shared form partial, Turbo Stream responses for create and destroy
- [ ] 11-03: Controller tests (CRUD + cross-user 404) and system tests (add medication, edit name, remove medication)

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

**Plans**:
- [ ] 12-01: DoseLogsController (create, destroy), routes, scoped to Current.user; Turbo Stream response on create
- [ ] 12-02: Dose log form on medication detail/show page; dose history list per medication with delete button
- [ ] 12-03: Controller tests (create, destroy, cross-user isolation) and system tests (log a dose, delete a dose, count updates)

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

**Plans**:
- [ ] 13-01: `remaining_doses` display on medication card; low-stock warning component (conditional CSS class / partial); dashboard integration for low-stock alert
- [ ] 13-02: Refill action — `PATCH /medications/:id/refill` route, controller action, updates starting_dose_count + refilled_at, Turbo Stream response
- [ ] 13-03: Controller tests for refill action; model tests for days_of_supply edge cases; system test for low-stock warning appearing and clearing after refill

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

**Plans**:
- [ ] 14-01: Adherence helper / service object — given a medication and a date, returns `{taken: N, scheduled: N, status: :on_track | :missed | :no_schedule}`; model/unit tests
- [ ] 14-02: Dashboard adherence card partial; logic to collect today's adherence for all preventer medications scoped to Current.user
- [ ] 14-03: Adherence history view — 7 / 30 day toggle, calendar grid partial, colour coding; controller action; system test for grid rendering and day status

---

### Phase 15: Health Events

**Goal**: A user can log a health event (illness episode, GP appointment, or prescription course) with a date and notes; they can edit or delete events; and health events appear as vertical markers on the peak flow trend chart.
**Why this matters**: Peak flow numbers alone don't explain why a chart dips — a logged illness or steroid course makes the correlation visible. This is what turns the chart from interesting to clinically useful for a GP conversation.
**Depends on**: Phase 14
**Requirements**: EVT-01, EVT-02, EVT-03

**Success Criteria** (what must be TRUE):
  1. A logged-in user can log a health event by selecting a type (illness episode / GP appointment / prescription course), entering a start date, optionally an end date, and optional notes — and the event appears in a health events history list.
  2. A user can edit any field of a health event and save the changes; they can delete an event and it is removed permanently.
  3. The peak flow trend chart displays a vertical line or marker at the date of each health event, visually distinguishable by event type; hovering or tapping the marker reveals the event type and date.
  4. A user cannot view, edit, or delete another user's health events (isolation enforced).

**Plans**:
- [ ] 15-01: HealthEvent model — user association, event_type enum (illness/appointment/prescription_course), started_on, ended_on (nullable), notes (ActionText rich text), validations, migrations, fixtures, model tests
- [ ] 15-02: HealthEventsController (index, new, create, edit, update, destroy), routes, views (list, form), Turbo Stream responses; controller tests and system tests
- [ ] 15-03: Peak flow chart integration — pass health event dates and types as JSON to the Stimulus chart controller; render vertical annotation lines using Chart.js annotation plugin (pinned via importmap) or canvas overlay; system test confirming markers appear

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
Phases execute in numeric order: 10 -> 11 -> 12 -> 13 -> 14 -> 15 -> 16 -> 17

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 10. Medication Data Layer | 0/3 | Not started | - |
| 11. Medication Management UI | 0/3 | Not started | - |
| 12. Dose Logging | 0/3 | Not started | - |
| 13. Dose Tracking & Low Stock | 0/3 | Not started | - |
| 14. Adherence Dashboard | 0/3 | Not started | - |
| 15. Health Events | 0/3 | Not started | - |
| 16. Account Management & Legal | 0/3 | Not started | - |
| 17. Onboarding Flow | 0/3 | Not started | - |

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
