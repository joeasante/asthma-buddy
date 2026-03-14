# Requirements: Asthma Buddy

**Defined:** 2026-03-06
**Core Value:** A reliable daily tracking companion that surfaces patterns — so users and their doctors actually understand what's happening with their asthma.

---

## v1 Requirements (Milestone 1)

### Authentication

- [ ] **AUTH-01**: User can create an account with email and password — *enables personalised tracking with data ownership*
- [ ] **AUTH-02**: User receives email verification after signup — *prevents fake accounts and ensures data integrity*
- [ ] **AUTH-03**: User can log in and stay logged in across browser sessions — *removes daily friction from the tracking habit*
- [ ] **AUTH-04**: User can log out from any page — *user controls their session*
- [ ] **AUTH-05**: User can reset their password via an email link — *reduces support burden and prevents lockouts*

### Symptom Logging

- [ ] **SYMP-01**: User can record a symptom entry with type, severity level, and timestamp — *core tracking loop; without this the app has no value*
- [ ] **SYMP-02**: User can add optional notes to a symptom entry — *captures context (what they were doing, where they were) that helps identify triggers*
- [ ] **SYMP-03**: User can view a chronological timeline of their symptom logs — *lets users see patterns over time*
- [ ] **SYMP-04**: User can filter symptom timeline by date range — *makes it usable for "show me the last week" before a doctor visit*
- [ ] **SYMP-05**: User can edit a symptom log they recorded — *corrects mistakes without needing to delete and re-enter*
- [ ] **SYMP-06**: User can delete a symptom log they recorded — *user controls their own data*
- [ ] **SYMP-07**: User can view severity trends across their symptom history — *surfaces patterns that individual entries miss*

### Peak Flow Tracking

- [ ] **PEAK-01**: User can manually enter a peak flow reading (numeric value + timestamp) — *core measurement; everything else depends on this*
- [ ] **PEAK-02**: User can set and update their personal best peak flow value — *required to calculate meaningful zone percentages*
- [ ] **PEAK-03**: System automatically calculates the zone (Green / Yellow / Red) for each reading based on personal best — *turns a raw number into actionable information*
- [ ] **PEAK-04**: User can view their peak flow readings with zone colour coding — *instant visual understanding of control level*
- [ ] **PEAK-05**: User can view a trend chart of peak flow readings over time — *reveals whether control is improving or deteriorating*
- [ ] **PEAK-06**: User can edit a peak flow reading — *corrects data entry errors*
- [ ] **PEAK-07**: User can delete a peak flow reading — *user controls their own data*

---

## v2 Requirements (Milestone 2 — Medication & Compliance)

### Medication Profile

- [x] **MED-01**: User can add a medication to their profile: name, type (reliever / preventer / combination / other), standard dose in puffs, and starting dose count — *enables the user to model the actual medications they use*
- [x] **MED-02**: User can optionally set a sick-day dose and a daily schedule (doses per day) for preventers — *captures the extra detail needed for adherence tracking*
- [x] **MED-03**: User can edit or remove a medication from their profile — *corrects mistakes; handles medication changes at review appointments*

### Dose Logging

- [x] **DOSE-01**: User can log a dose taken: which medication, how many puffs, and timestamp — *creates the event log that drives all dose tracking*
- [x] **DOSE-02**: User can delete a dose log entry they recorded — *user controls their own data; corrects accidental double-logs*

### Dose Tracking

- [x] **TRACK-01**: System calculates and displays remaining doses for each medication (starting count − logged doses) — *prevents the user running out without realising*
- [x] **TRACK-02**: System shows a low-stock warning when remaining doses fall below 14 days' estimated supply — *14-day threshold gives time to request a prescription before running out*
- [x] **TRACK-03**: User can mark a medication as refilled, resetting the dose count to the new starting value — *models the real-world prescription renewal cycle*

### Adherence Tracking

- [x] **ADH-01**: Dashboard shows a preventer adherence indicator for today: doses taken vs scheduled (e.g. 1/2) — *immediate feedback on whether the preventer has been taken; key for ICS compliance*
- [x] **ADH-02**: User can view a recent adherence history for their preventers (last 7 or 30 days) — *surfaces patterns; supports conversations with a GP or asthma nurse*

### Health Events

- [x] **EVT-01**: User can log a health event with a type (illness episode / GP appointment / prescription course), date, and optional notes — *captures the external events that affect asthma control and help explain chart patterns*
- [x] **EVT-02**: User can edit or delete a health event — *user controls their own data*
- [x] **EVT-03**: Health events appear as vertical markers on the peak flow trend chart — *visually correlates events (illness, steroids) with changes in peak flow readings*

### Reliever Usage History

- [ ] **REL-01**: User can view their reliever usage history showing daily puffs logged over the past 7 or 30 days, with a period toggle — *enables pattern recognition; lets user and GP see how frequently reliever is being used*
- [ ] **REL-02**: Weeks where reliever usage exceeded 2 times are highlighted on the view, and a correlation panel shows reliever frequency alongside peak flow readings for the same period — *surfaces the clinical 2×/week threshold as a clear warning; connects reliever overuse to peak flow dips*

### Account Management

- [x] **ACC-01**: User can delete their account — all data (readings, logs, medications, events) is permanently erased (GDPR right to erasure) — *legal requirement; builds trust that the app is not a data trap*
- [x] **ACC-02**: Account deletion requires a confirmation step (type "DELETE" or re-enter password) — *prevents accidental deletion of irreplaceable health data*

### Onboarding

- [x] **ONBD-01**: After signup, a new user is prompted to complete onboarding: set personal best, add first medication — *reduces the activation gap; a first-time user with no data sees no value*
- [x] **ONBD-02**: Onboarding can be skipped and completed later — *respects the user who signs up before they have their inhaler to hand*

### Legal & Compliance

- [x] **LEGAL-01**: App has a Terms of Service page linked from the footer — *required for public launch*
- [x] **LEGAL-02**: App has a Privacy Policy page (UK GDPR + Data Protection Act 2018 compliant) — *legal requirement; reassures users their health data is handled responsibly*
- [x] **LEGAL-03**: App displays a brief session cookie notice on first visit (informational — no consent banner needed for essential session cookies only) — *GDPR compliance for essential cookies*

### Error Pages

- [ ] **ERR-01**: App shows a branded 404 Not Found page that matches the visual design, with a recovery link to the dashboard or home page — *prevents users from seeing a broken Rails default; maintains trust during navigation errors*
- [ ] **ERR-02**: App shows a branded 500 Internal Server Error page that matches the visual design, with a recovery link — *prevents users from seeing a broken Rails default during incidents; maintains trust under failure conditions*

---

## v3 Requirements (Milestone 3 — SaaS Foundation)

### RBAC (Role-Based Access Control)

- [ ] **RBAC-01**: Admin can assign roles (admin/member) to users via the admin panel — *replaces boolean flag with extensible role system*
- [ ] **RBAC-02**: All resource access is authorized via Pundit policies, with `verify_authorized` safety net on every controller — *prevents forgotten authorization checks*
- [ ] **RBAC-03**: Existing admin functionality continues working after migration from boolean to role enum — *zero-downtime migration*
- [ ] **RBAC-04**: Admin can toggle registration open/closed; closed registration shows a "registration closed" page to visitors — *controls who can access the health app*

### MFA (Multi-Factor Authentication)

- [ ] **MFA-01**: User can enable TOTP-based MFA by scanning a QR code with an authenticator app — *protects health data with second factor*
- [ ] **MFA-02**: After password verification, MFA-enabled users must enter a TOTP code before gaining access — *prevents unauthorized access even with stolen password*
- [ ] **MFA-03**: User receives 10 one-time recovery codes when enabling MFA, downloadable as text — *prevents permanent lockout if phone is lost*
- [ ] **MFA-04**: User can disable MFA from their settings after re-authenticating — *user controls their own security settings*
- [ ] **MFA-05**: TOTP secrets are encrypted at rest using Rails Active Record Encryption — *UK GDPR security measure for authentication secrets*

### REST API

- [ ] **API-01**: User can generate an API key from settings; the key is shown once and stored as a SHA-256 hash — *enables programmatic access without exposing credentials*
- [ ] **API-02**: API requests authenticate via Bearer token in Authorization header — *standard API authentication pattern*
- [ ] **API-03**: Versioned JSON endpoints at `/api/v1/` expose symptom logs, peak flow readings, medications, dose logs, and health events — *GDPR data portability and integration support*
- [ ] **API-04**: API responses follow a consistent JSON format with pagination, filtering, and error handling — *usable API for third-party consumers*
- [ ] **API-05**: API requests are rate-limited separately from web requests via Rack::Attack — *prevents API abuse without affecting web users*
- [ ] **API-06**: User can revoke an API key from settings — *user controls their API access*

### Stripe Billing

- [ ] **BILL-01**: App offers free and premium subscription plans; free users have feature limits — *monetization foundation*
- [ ] **BILL-02**: User can subscribe to a premium plan via Stripe Checkout (hosted payment page) — *PCI compliance without handling card data*
- [ ] **BILL-03**: User can manage their subscription (cancel, update payment method) via Stripe Customer Portal — *self-service billing management*
- [ ] **BILL-04**: Stripe webhooks are processed asynchronously via Solid Queue with idempotency — *reliable billing state sync with SQLite write safety*
- [ ] **BILL-05**: Feature access is gated by subscription plan using Pundit policies — *premium features only for paying users*
- [ ] **BILL-06**: Billing UI shows current plan, next billing date, and subscription status — *transparency for the user*

### Cross-Feature Integration Tests

- [ ] **TEST-01**: Integration tests verify MFA + API key interaction (API keys bypass MFA by design) — *confirms dual auth paths work correctly*
- [ ] **TEST-02**: Integration tests verify billing + feature gating across plan changes — *confirms upgrade/downgrade triggers correct access changes*
- [ ] **TEST-03**: Integration tests verify RBAC policies apply identically to web and API controllers — *confirms no authorization bypass via API*
- [ ] **TEST-04**: Stripe webhook processing is tested with WebMock/VCR fixtures — *reliable CI without hitting Stripe API*

---

## Future Requirements (Milestone 4+)

### Environmental Monitoring

- **ENV-01**: System fetches and displays current weather, pollen count, and AQI for user's location
- **ENV-02**: User receives an alert when environmental conditions increase their personal asthma risk

### Reports

- **RPT-01**: User can generate a report of symptom history for a given date range
- **RPT-02**: User can generate a report of peak flow trends
- **RPT-03**: User can export a report as PDF
- **RPT-04**: User can export a report as CSV

### Caregiver Access

- **CARE-01**: User can invite a caregiver to view their data (with consent)
- **CARE-02**: Caregiver can view a shared monitoring dashboard for the patient
- **CARE-03**: Caregiver receives alerts when patient enters Yellow or Red zone

### Analytics

- **ANLX-01**: User can view advanced insights identifying patterns across all tracked data
- **ANLX-02**: System surfaces correlations between triggers, environmental conditions, and symptom severity

---

## Out of Scope

| Feature | Reason |
|---------|--------|
| OAuth login (Google, GitHub) | Email/password sufficient; MFA provides stronger security |
| Native mobile app | PWA covers mobile install; native is a separate project |
| Smart inhaler integration | Future enhancement; requires hardware partnership |
| Telehealth integrations | Future; out of scope for personal tracking tool |
| Community / social features | Not aligned with core value of individual tracking |
| AI/ML predictive analytics | Future; needs sufficient data first |
| SMS-based MFA | SIM-swap vulnerability; TOTP is more secure and free |
| JWT/OAuth2 for API auth | Over-engineering for current scale; API keys are simpler and sufficient |
| Custom roles beyond admin/member | YAGNI; two roles cover all current needs |

---

## Traceability

### Milestone 1 (v1.0 — Complete)

| Requirement | Phase | Status |
|-------------|-------|--------|
| AUTH-01 | Phase 2 — Authentication | Complete |
| AUTH-02 | Phase 2 — Authentication | Complete |
| AUTH-03 | Phase 2 — Authentication | Complete |
| AUTH-04 | Phase 2 — Authentication | Complete |
| AUTH-05 | Phase 2 — Authentication | Complete |
| SYMP-01 | Phase 3 — Symptom Recording | Complete |
| SYMP-02 | Phase 3 — Symptom Recording | Complete |
| SYMP-03 | Phase 5 — Symptom Timeline | Complete |
| SYMP-04 | Phase 5 — Symptom Timeline | Complete |
| SYMP-05 | Phase 4 — Symptom Management | Complete |
| SYMP-06 | Phase 4 — Symptom Management | Complete |
| SYMP-07 | Phase 5 — Symptom Timeline | Complete |
| PEAK-01 | Phase 6 — Peak Flow Recording | Complete |
| PEAK-02 | Phase 6 — Peak Flow Recording | Complete |
| PEAK-03 | Phase 6 — Peak Flow Recording | Complete |
| PEAK-04 | Phase 7 — Peak Flow Display | Complete |
| PEAK-05 | Phase 8 — Peak Flow Trends | Complete |
| PEAK-06 | Phase 7 — Peak Flow Display | Complete |
| PEAK-07 | Phase 7 — Peak Flow Display | Complete |

### Milestone 2 (v2.0 — Complete 2026-03-14)

| Requirement | Phase | Status |
|-------------|-------|--------|
| MED-01 | Phase 10 — Medication Data Layer | Complete |
| MED-02 | Phase 10 — Medication Data Layer | Complete |
| MED-03 | Phase 11 — Medication Management UI | Complete |
| DOSE-01 | Phase 12 — Dose Logging | Complete |
| DOSE-02 | Phase 12 — Dose Logging | Complete |
| TRACK-01 | Phase 13 — Dose Tracking | Complete |
| TRACK-02 | Phase 13 — Dose Tracking | Complete |
| TRACK-03 | Phase 13 — Dose Tracking | Complete |
| ADH-01 | Phase 14 — Adherence Dashboard | Complete |
| ADH-02 | Phase 14 — Adherence Dashboard | Complete |
| EVT-01 | Phase 15 — Health Events | Complete |
| EVT-02 | Phase 15 — Health Events | Complete |
| EVT-03 | Phase 15 — Health Events | Complete |
| REL-01 | Phase 15.1 — Reliever Usage History | Complete |
| REL-02 | Phase 15.1 — Reliever Usage History | Complete |
| ACC-01 | Phase 16 — Account Management | Complete |
| ACC-02 | Phase 16 — Account Management | Complete |
| ONBD-01 | Phase 17 — Onboarding | Complete |
| ONBD-02 | Phase 17 — Onboarding | Complete |
| LEGAL-01 | Phase 16 — Account Management | Complete |
| LEGAL-02 | Phase 16 — Account Management | Complete |
| LEGAL-03 | Phase 16 — Account Management | Complete |
| ERR-01 | Phase 20 — Legal Pages & Error Pages | Complete |
| ERR-02 | Phase 20 — Legal Pages & Error Pages | Complete |

### Milestone 3 (v3.0 — In Progress)

| Requirement | Phase | Status |
|-------------|-------|--------|
| RBAC-01 | Phase 26 — Role-Based Access Control | Complete |
| RBAC-02 | Phase 26 — Role-Based Access Control | Complete |
| RBAC-03 | Phase 26 — Role-Based Access Control | Complete |
| RBAC-04 | Phase 26 — Role-Based Access Control | Complete |
| MFA-01 | Phase 27 — Multi-Factor Authentication | Pending |
| MFA-02 | Phase 27 — Multi-Factor Authentication | Pending |
| MFA-03 | Phase 27 — Multi-Factor Authentication | Pending |
| MFA-04 | Phase 27 — Multi-Factor Authentication | Pending |
| MFA-05 | Phase 27 — Multi-Factor Authentication | Pending |
| API-01 | Phase 28 — REST API | Pending |
| API-02 | Phase 28 — REST API | Pending |
| API-03 | Phase 28 — REST API | Pending |
| API-04 | Phase 28 — REST API | Pending |
| API-05 | Phase 28 — REST API | Pending |
| API-06 | Phase 28 — REST API | Pending |
| BILL-01 | Phase 29 — Stripe Billing | Pending |
| BILL-02 | Phase 29 — Stripe Billing | Pending |
| BILL-03 | Phase 29 — Stripe Billing | Pending |
| BILL-04 | Phase 29 — Stripe Billing | Pending |
| BILL-05 | Phase 29 — Stripe Billing | Pending |
| BILL-06 | Phase 29 — Stripe Billing | Pending |
| TEST-01 | Phase 30 — Cross-Feature Integration Tests | Pending |
| TEST-02 | Phase 30 — Cross-Feature Integration Tests | Pending |
| TEST-03 | Phase 30 — Cross-Feature Integration Tests | Pending |
| TEST-04 | Phase 30 — Cross-Feature Integration Tests | Pending |

**Coverage:**
- v1 requirements: 19 total — 19 mapped, 19 complete
- v2 requirements: 22 total — 22 mapped, 22 complete (+ 2 REL requirements)
- v3 requirements: 22 total — 22 mapped, 4 complete

---
*Requirements defined: 2026-03-06*
*Last updated: 2026-03-14 — Phase 26 complete; RBAC-01 through RBAC-04 verified*
