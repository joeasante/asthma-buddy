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

## v2 Requirements (Milestone 2)

### Medication Management

- **MED-01**: User can maintain a list of their medications (name, type, dosage, frequency)
- **MED-02**: User can log when they take a dose of a medication
- **MED-03**: User can set reminders for scheduled medications
- **MED-04**: User can view their medication adherence statistics

### Trigger Tracking

- **TRIG-01**: User can record exposure to a potential asthma trigger (type, timestamp, notes)
- **TRIG-02**: System identifies correlations between trigger exposures and symptom events
- **TRIG-03**: User can view a summary of their most common triggers

### Dashboard

- **DASH-01**: User sees a dashboard summarising their current asthma control status
- **DASH-02**: Dashboard shows today's symptom and peak flow summary
- **DASH-03**: Dashboard highlights any Red zone readings requiring attention

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

| Requirement | Phase | Status |
|-------------|-------|--------|
| AUTH-01 | Phase 2 — Authentication | Pending |
| AUTH-02 | Phase 2 — Authentication | Pending |
| AUTH-03 | Phase 2 — Authentication | Pending |
| AUTH-04 | Phase 2 — Authentication | Pending |
| AUTH-05 | Phase 2 — Authentication | Pending |
| SYMP-01 | Phase 3 — Symptom Recording | Pending |
| SYMP-02 | Phase 3 — Symptom Recording | Pending |
| SYMP-03 | Phase 5 — Symptom Timeline | Pending |
| SYMP-04 | Phase 5 — Symptom Timeline | Pending |
| SYMP-05 | Phase 4 — Symptom Management | Pending |
| SYMP-06 | Phase 4 — Symptom Management | Pending |
| SYMP-07 | Phase 5 — Symptom Timeline | Pending |
| PEAK-01 | Phase 6 — Peak Flow Recording | Pending |
| PEAK-02 | Phase 6 — Peak Flow Recording | Pending |
| PEAK-03 | Phase 6 — Peak Flow Recording | Pending |
| PEAK-04 | Phase 7 — Peak Flow Display and Management | Pending |
| PEAK-05 | Phase 8 — Peak Flow Trends | Pending |
| PEAK-06 | Phase 7 — Peak Flow Display and Management | Pending |
| PEAK-07 | Phase 7 — Peak Flow Display and Management | Pending |

**Coverage:**
- v1 requirements: 19 total
- Mapped to phases: 19
- Unmapped: 0 ✓ (100% coverage)

---
*Requirements defined: 2026-03-06*
*Last updated: 2026-03-06 after roadmap creation*
