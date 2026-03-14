---
created: 2026-03-13T18:58:54Z
updated: 2026-03-13T19:45:00Z
title: Phases 23–25 — Compliance, Security, Admin & Clinical Intelligence
area: ui
files:
  - app/controllers/admin/base_controller.rb
  - app/controllers/sessions_controller.rb
  - app/models/user.rb
  - app/views/settings/show.html.erb
  - .ariadna_planning/phases/23-compliance-security-accessibility/PHASE.md
  - .ariadna_planning/phases/24-admin-observability/PHASE.md
  - .ariadna_planning/phases/25-clinical-intelligence/PHASE.md
---

## Problem

Three categories of gaps identified in a design review session (2026-03-13):

1. **Legal/Security baseline not met** — no rate limiting, no session timeout, no GDPR data export, no medical device disclaimer
2. **Zero operational visibility** — no signup notifications, no user list, no usage metrics; admin management requires Rails console
3. **Clinical intelligence missing** — data is shown but not interpreted; no GP appointment summary

## Solution

**Three phased plans** — prioritised with compliance and security first.

### Phase 23: Compliance, Security & Accessibility (do first)
Plan: `.ariadna_planning/phases/23-compliance-security-accessibility/PHASE.md`

- **23-01 Security**: rack-attack rate limiting (login 5/IP/20s, signup 3/IP/hour) + idle session timeout (60 min)
- **23-02 WCAG 2.2**: colour-not-alone fixes on zone indicators; focus-not-obscured fix for bottom nav (SC 2.4.11); chart accessible text fallbacks; target size audit (SC 2.5.8)
- **23-03 GDPR**: data export `/account/export` (Art. 20 right to portability); medical device disclaimer in footer + Terms; data retention policy in Privacy Policy; `SECURITY.md` breach notification procedure (Art. 33, 72-hour ICO window)

### Phase 24: Admin & Observability (do second)
Plan: `.ariadna_planning/phases/24-admin-observability/PHASE.md`

- **24-01**: `last_sign_in_at` + `sign_in_count` migration; `SessionsController` tracking; `AdminMailer.new_signup` email notification
- **24-02**: `/admin/users` — user table, admin toggle, self-demotion guard, last-admin guard, confirm dialog, Rails.logger audit trail; Settings link
- **24-03**: `/admin` stats dashboard — total/new/WAU/MAU/never-returned stat cards + recent signups + most active tables

### Phase 25: Clinical Intelligence (do third)
Plan: `.ariadna_planning/phases/25-clinical-intelligence/PHASE.md`

- **25-01**: Dashboard interpretation sentence; 2×/week GINA reliever threshold warning; personal best aging alert (>18 months)
- **25-02**: `/appointment-summary` — print-optimised 30-day summary for GP consultations (peak flow zone breakdown, symptoms, reliever use, medications, health events, print CSS)

## Already Done (2026-03-13)
- Dashboard `@recent_symptoms` week-scoped (was unbounded)
- Dashboard `@recent_health_events` scoped to ongoing + last 14 days (was any 3 events)
- Peak Flow page: chart moved before filter bar
- Symptoms page: chart moved before filter bar
