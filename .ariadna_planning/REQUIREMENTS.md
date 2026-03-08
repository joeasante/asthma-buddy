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

---

## v2 Requirements (Milestone 3)

### Environmental Monitoring

- **ENV-01**: System fetches and displays current weather, pollen count, and AQI for user's location
- **ENV-02**: User receives an alert when environmental conditions increase their personal asthma risk

### Reports

- **RPT-01**: User can generate a report of symptom history for a given date range
- **RPT-02**: User can generate a report of peak flow trends
- **RPT-03**: User can export a report as PDF
- **RPT-04**: User can export a report as CSV

---

## v2 Requirements (Milestone 4)

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
| OAuth login (Google, GitHub) | Email/password sufficient for v1; can add later |
| Native mobile app | PWA covers mobile install; native is a separate project |
| Smart inhaler integration | Future enhancement; requires hardware partnership |
| Telehealth integrations | Future; out of scope for personal tracking tool |
| Community / social features | Not aligned with core value of individual tracking |
| AI/ML predictive analytics | Future; needs sufficient data first |
| Billing / subscriptions | Not monetising in v1 |

---

## Traceability

### Milestone 1 (v1.0 — Complete)

| Requirement | Phase | Status |
|-------------|-------|--------|
| AUTH-01 | Phase 2 — Authentication | ✅ Complete |
| AUTH-02 | Phase 2 — Authentication | ✅ Complete |
| AUTH-03 | Phase 2 — Authentication | ✅ Complete |
| AUTH-04 | Phase 2 — Authentication | ✅ Complete |
| AUTH-05 | Phase 2 — Authentication | ✅ Complete |
| SYMP-01 | Phase 3 — Symptom Recording | ✅ Complete |
| SYMP-02 | Phase 3 — Symptom Recording | ✅ Complete |
| SYMP-03 | Phase 5 — Symptom Timeline | ✅ Complete |
| SYMP-04 | Phase 5 — Symptom Timeline | ✅ Complete |
| SYMP-05 | Phase 4 — Symptom Management | ✅ Complete |
| SYMP-06 | Phase 4 — Symptom Management | ✅ Complete |
| SYMP-07 | Phase 5 — Symptom Timeline | ✅ Complete |
| PEAK-01 | Phase 6 — Peak Flow Recording | ✅ Complete |
| PEAK-02 | Phase 6 — Peak Flow Recording | ✅ Complete |
| PEAK-03 | Phase 6 — Peak Flow Recording | ✅ Complete |
| PEAK-04 | Phase 7 — Peak Flow Display | ✅ Complete |
| PEAK-05 | Phase 8 — Peak Flow Trends | ✅ Complete |
| PEAK-06 | Phase 7 — Peak Flow Display | ✅ Complete |
| PEAK-07 | Phase 7 — Peak Flow Display | ✅ Complete |

### Milestone 2 (v2.0 — In Progress)

| Requirement | Phase | Status |
|-------------|-------|--------|
| MED-01 | Phase 10 — Medication Data Layer | Pending |
| MED-02 | Phase 10 — Medication Data Layer | Pending |
| MED-03 | Phase 11 — Medication Management UI | Pending |
| DOSE-01 | Phase 12 — Dose Logging | Pending |
| DOSE-02 | Phase 12 — Dose Logging | Pending |
| TRACK-01 | Phase 13 — Dose Tracking | Pending |
| TRACK-02 | Phase 13 — Dose Tracking | Pending |
| TRACK-03 | Phase 13 — Dose Tracking | Pending |
| ADH-01 | Phase 14 — Adherence Dashboard | Pending |
| ADH-02 | Phase 14 — Adherence Dashboard | Pending |
| EVT-01 | Phase 15 — Health Events | Pending |
| EVT-02 | Phase 15 — Health Events | Pending |
| EVT-03 | Phase 15 — Health Events | Pending |
| ACC-01 | Phase 16 — Account Management | Pending |
| ACC-02 | Phase 16 — Account Management | Pending |
| ONBD-01 | Phase 17 — Onboarding | Pending |
| ONBD-02 | Phase 17 — Onboarding | Pending |
| LEGAL-01 | Phase 16 — Account Management | Pending |
| LEGAL-02 | Phase 16 — Account Management | Pending |
| LEGAL-03 | Phase 16 — Account Management | Pending |

**Coverage:**
- v1 requirements: 19 total — 19 mapped, 0 unmapped ✓
- v2 requirements: 20 total — 20 mapped, 0 unmapped ✓

---
*Requirements defined: 2026-03-06*
*Last updated: 2026-03-08 — Milestone 2 requirements defined*
