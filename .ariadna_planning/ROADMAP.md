# Roadmap: Asthma Buddy — Milestone 1

## Overview

Milestone 1 establishes the complete foundation of Asthma Buddy: a secure, multi-user Rails application where people with asthma can log symptoms and record peak flow readings. The nine phases move from bare infrastructure through authentication, into symptom logging (recording, managing, viewing), then into peak flow tracking (entry, zone display, trend charting), and finally accessibility and polish. When complete, a user can open the app, create an account, log their daily symptoms and peak flow readings, view their history with zone colour coding, and spot patterns over time.

**Product vision:** Users log consistently enough that patterns emerge — reducing asthma attacks and improving medication adherence.
**Building for:** Person with asthma who wants frictionless daily logging and is frustrated by forgetting to track or losing paper diaries.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Foundation** - Rails app infrastructure, database configuration, and CI baseline
- [x] **Phase 2: Authentication** - User accounts, sessions, email verification, and password reset — completed 2026-03-06
- [ ] **Phase 3: Symptom Recording** - Create symptom entries with type, severity, timestamp, and notes
- [ ] **Phase 4: Symptom Management** - Edit and delete symptom entries
- [ ] **Phase 5: Symptom Timeline** - Chronological view, date filtering, and severity trends
- [ ] **Phase 6: Peak Flow Recording** - Enter readings, set personal best, calculate zones
- [x] **Phase 7: Peak Flow Display and Management** - View readings with zone colour coding, edit, delete — Complete 2026-03-07
- [ ] **Phase 8: Peak Flow Trends** - Trend chart of readings over time
- [ ] **Phase 9: Accessibility and Polish** - WCAG 2.2 AA compliance, performance, PWA manifest

## Phase Details

### Phase 1: Foundation
**Goal**: A working Rails 8 application with a configured database, test suite baseline, and deployment pipeline in place so all subsequent phases build on solid ground.
**Why this matters**: Enables everything that follows — without the infrastructure layer there is nothing to build on.
**Depends on**: Nothing (first phase)
**Requirements**: None (foundational — no v1 functional requirements map here; this unblocks AUTH-01 through PEAK-07)
**Success Criteria** (what must be TRUE):
  1. The application boots in development with `bin/rails server` and returns a 200 response on the root path.
  2. The test suite runs with `bin/rails test` and produces zero failures on an empty test baseline.
  3. SQLite is running in WAL mode and the database schema can be created with `bin/rails db:schema:load`.
  4. A Kamal deploy configuration exists and a staging deploy succeeds without errors.
**Plans**: 4 plans

Plans:
- [ ] 01-01-PLAN.md — Enable WAL mode SQLite via database.yml or initializer
- [ ] 01-02-PLAN.md — Root route, HomeController, and application layout with nav shell
- [ ] 01-03-PLAN.md — Minitest baseline: HomeController integration test and system test setup
- [ ] 01-04-PLAN.md — Kamal staging deployment config and CI verification (has checkpoint)

---

### Phase 2: Authentication
**Goal**: Users can create accounts, verify their email, log in and stay logged in across sessions, log out from any page, and recover a forgotten password.
**Why this matters**: Users need a verified identity before they can own their health data — without this every subsequent feature is inaccessible and the multi-user isolation required from day one cannot be enforced.
**Depends on**: Phase 1
**Requirements**: AUTH-01, AUTH-02, AUTH-03, AUTH-04, AUTH-05
**Success Criteria** (what must be TRUE):
  1. A new visitor can register with an email address and password and receives a verification email.
  2. A user cannot log in until their email address is verified.
  3. A logged-in user remains authenticated after closing and reopening the browser (persistent session).
  4. A user can click "Sign out" from any page and is immediately logged out.
  5. A user who has forgotten their password can request a reset link, receive it by email, and set a new password.
**Plans**: 3 plans

Plans:
- [ ] 02-01-PLAN.md — Auth scaffold + RegistrationsController + User model with signup and login
- [ ] 02-02-PLAN.md — Email verification mailer, token flow, and login gate on verified email
- [ ] 02-03-PLAN.md — Persistent sessions, password reset, nav auth links, route protection, system test

---

### Phase 3: Symptom Recording
**Goal**: An authenticated user can create a symptom log entry specifying the symptom type, a severity level, a timestamp, and optional free-text notes.
**Why this matters**: This is the core tracking loop — without the ability to record symptoms the app delivers no value to the person with asthma.
**Depends on**: Phase 2
**Requirements**: SYMP-01, SYMP-02
**Success Criteria** (what must be TRUE):
  1. A logged-in user can open the "Log Symptom" form, select a symptom type from a predefined list, choose a severity level, confirm or adjust the timestamp, and submit the entry successfully.
  2. Optional notes can be added to a symptom entry and are saved and displayed as entered.
  3. A submitted entry appears immediately in the user's data without requiring a page refresh.
  4. A user cannot see or interact with another user's symptom entries (multi-user isolation enforced).
**Plans**: 3 plans

Plans:
- [ ] 03-01-PLAN.md — SymptomLog model, ActionText install, enums (4 types, 3 severities), user association, model tests
- [ ] 03-02-PLAN.md — SymptomLogs controller (index + create), views, Turbo Stream create response, controller tests
- [ ] 03-03-PLAN.md — System tests: complete logging flow, form clear, notes, multi-user isolation

---

### Phase 4: Symptom Management
**Goal**: A user can edit or delete any symptom entry they previously recorded.
**Why this matters**: People make data entry mistakes — giving users control over their own records removes the frustration of permanent incorrect data and builds trust in the app as a reliable diary.
**Depends on**: Phase 3
**Requirements**: SYMP-05, SYMP-06
**Success Criteria** (what must be TRUE):
  1. A user can open an existing symptom entry, change any field (type, severity, timestamp, notes), save the change, and see the updated values immediately.
  2. A user can delete a symptom entry and it is removed from their record permanently.
  3. A user cannot edit or delete another user's symptom entries — attempting to do so returns a 404 or redirect.
**Plans**: 2 plans

Plans:
- [ ] 04-01-PLAN.md — Routes, controller (edit/update/destroy), views (inline Turbo Frame edit, delete button, Turbo Stream responses)
- [ ] 04-02-PLAN.md — Controller tests (edit/update/destroy own + cross-user) and system tests (inline edit flow, delete flow)

---

### Phase 5: Symptom Timeline
**Goal**: A user can view all their symptom logs in reverse-chronological order, filter them by date range, and see a summary of severity trends across their history.
**Why this matters**: The timeline turns isolated log entries into a picture of the user's asthma over time — this is where patterns become visible before a doctor visit.
**Depends on**: Phase 4
**Requirements**: SYMP-03, SYMP-04, SYMP-07
**Success Criteria** (what must be TRUE):
  1. A user's symptom history is displayed in reverse-chronological order with type, severity, and timestamp visible at a glance.
  2. A user can enter a start date and end date to filter the timeline and see only entries within that range.
  3. A user can see a severity trend summary (e.g., counts of mild / moderate / severe entries) across their history so they can identify whether their symptoms are getting better or worse.
  4. The timeline loads within 2 seconds for a user with up to 365 entries.
**Plans**: 3 plans

Plans:
- [ ] 05-01-PLAN.md — Model scopes, controller filter/pagination, timeline views (filter bar, trend bar, compact rows, pagination)
- [ ] 05-02-PLAN.md — Model tests, controller filter tests, system test for Turbo Frame chip interaction
- [ ] 05-03-PLAN.md — Gap closure: trend bar live update on create, chip active state fix, datetime step fix

---

### Phase 6: Peak Flow Recording
**Goal**: A user can manually enter a peak flow reading with a numeric value and timestamp, set their personal best value, and have the system automatically calculate and assign a zone (Green / Yellow / Red) to each reading.
**Why this matters**: A raw peak flow number means nothing without context — the personal best and zone calculation turn it into actionable information that tells the user (and their doctor) whether their asthma is under control.
**Depends on**: Phase 2
**Requirements**: PEAK-01, PEAK-02, PEAK-03
**Success Criteria** (what must be TRUE):
  1. A logged-in user can enter a peak flow reading (numeric value in L/min) and a timestamp and save it successfully.
  2. A user can set their personal best peak flow value in their profile or settings; this value persists across sessions.
  3. When a reading is saved, the system automatically computes the zone: Green (>= 80% of personal best), Yellow (50-79%), Red (< 50%) — and stores it against the reading.
  4. A user cannot record or view another user's peak flow data (isolation enforced).
**Plans**: 5 plans

Plans:
- [ ] 06-01-PLAN.md — PeakFlowReading + PersonalBestRecord models, migrations, zone calculation, fixtures, model tests
- [ ] 06-02-PLAN.md — Settings routes, SettingsController, personal best form with 100-900 validation
- [ ] 06-03-PLAN.md — PeakFlowReadingsController (new + create), entry form, Turbo Stream response, zone flash
- [ ] 06-04-PLAN.md — Controller tests (recording + settings) and system tests for full recording flow
- [ ] 06-05-PLAN.md — Gap closure: required field, form reset, flash replace, zone colour in flash

---

### Phase 7: Peak Flow Display and Management
**Goal**: A user can view all their peak flow readings with zone colour coding applied, and can edit or delete individual readings.
**Why this matters**: Instant visual feedback — green, yellow, red — gives the user an immediate, actionable read on their asthma control without needing to interpret numbers.
**Depends on**: Phase 6
**Requirements**: PEAK-04, PEAK-06, PEAK-07
**Success Criteria** (what must be TRUE):
  1. A user's peak flow reading list shows each reading's value, timestamp, and zone with a distinct colour (green / yellow / red) so the zone is identifiable at a glance without reading the label.
  2. A user can edit a peak flow reading (value or timestamp), save the change, and see the zone recalculated and updated immediately.
  3. A user can delete a peak flow reading and it is removed permanently.
  4. A user cannot edit or delete another user's readings.
**Plans**: TBD

Plans:
- [x] 07-01: Build peak flow readings index view with zone colour coding (CSS classes per zone)
- [x] 07-02: Build edit/update/destroy with Turbo Streams, cross-user 404 isolation
- [x] 07-03: Controller tests — 18 new cases, 170 total, 0 failures
- [x] 07-04: System tests — 7 browser tests for zone badges, inline edit, delete, isolation

---

### Phase 8: Peak Flow Trends
**Goal**: A user can view a trend chart of their peak flow readings over time, showing how their readings and zone distribution change across days and weeks.
**Why this matters**: A list of numbers reveals nothing about trajectory — the trend chart is what lets the user and their doctor see whether asthma control is improving, stable, or deteriorating, which is core to the product vision.
**Depends on**: Phase 7
**Requirements**: PEAK-05
**Success Criteria** (what must be TRUE):
  1. A user can navigate to a peak flow trends view and see their readings plotted over time with zone boundaries (Green / Yellow / Red) visually indicated.
  2. The chart renders using data the server provides — no external API calls to third-party chart services.
  3. The trends view loads within 2 seconds for up to 365 readings.
**Plans**: TBD

Plans:
- [ ] 08-01: Design and implement data serialisation for chart (JSON endpoint or inline data)
- [ ] 08-02: Integrate a Stimulus-driven charting library (e.g., Chart.js via importmap)
- [ ] 08-03: Render peak flow trend chart with zone bands
- [ ] 08-04: Add date range selector to filter chart data
- [ ] 08-05: Write Minitest coverage for data serialisation; system test for chart render

---

### Phase 9: Accessibility and Polish
**Goal**: The entire application meets WCAG 2.2 AA accessibility requirements, pages load within 2 seconds, and the PWA web app manifest is in place so the app is installable on mobile.
**Why this matters**: The primary user logs symptoms on their phone, often when symptomatic — if the app is slow, uninstallable, or unusable with assistive technology it fails the people who most need it.
**Depends on**: Phase 8
**Requirements**: None (cross-cutting quality requirement across all features)
**Success Criteria** (what must be TRUE):
  1. All pages pass an automated WCAG 2.2 AA audit (axe or equivalent) with zero violations.
  2. All interactive elements (forms, buttons, navigation) are fully usable by keyboard alone.
  3. All pages return a Lighthouse performance score of >= 90 and load within 2 seconds on a 4G connection.
  4. The web app manifest is present, the app can be installed to a mobile home screen, and the install prompt appears on a supported browser.
**Plans**: TBD

Plans:
- [ ] 09-01: Audit all views with axe — fix colour contrast, label associations, heading hierarchy
- [ ] 09-02: Keyboard navigation audit — focus management, skip links, modal traps
- [ ] 09-03: Semantic HTML pass — landmark regions, ARIA roles only where native HTML is insufficient
- [ ] 09-04: Add PWA web app manifest and theme colour meta tags
- [ ] 09-05: Performance audit — database query counts, N+1 checks, asset compression
- [ ] 09-06: System test suite for critical user flows end-to-end

---

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 8 -> 9

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 0/4 | Not started | - |
| 2. Authentication | 3/3 | Complete | 2026-03-06 |
| 3. Symptom Recording | 0/3 | Not started | - |
| 4. Symptom Management | 0/2 | Not started | - |
| 5. Symptom Timeline | 0/3 | Not started | - |
| 6. Peak Flow Recording | 0/5 | Not started | - |
| 7. Peak Flow Display and Management | 0/5 | Not started | - |
| 8. Peak Flow Trends | 0/5 | Not started | - |
| 9. Accessibility and Polish | 0/6 | Not started | - |
