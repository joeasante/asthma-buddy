# Asthma Buddy

## What This Is

Asthma Buddy is a web application that helps people monitor and manage asthma more effectively. Users track symptoms, record peak flow readings, manage medications, identify triggers, and follow personalised action plans. Built as a Progressive Web App so it's installable on mobile and works offline.

## Core Value

A reliable daily tracking companion that surfaces patterns — so users and their doctors actually understand what's happening with their asthma.

## Who This Serves

- **Person with asthma (primary)** — Wants frictionless daily logging. Frustrated by forgetting to track or losing paper diaries. Cares about speed and simplicity over features.
- **Parent managing a child's asthma** — Needs a shared view of their child's data. Worried about missing warning signs.
- **Caregiver** — Monitors patients remotely with consent. Wants alerts when things go wrong.
- **Healthcare provider** — Needs a summary of recent history before appointments. Wants exportable reports.

Built initially for personal use (self or family), then opened to others — multi-user isolation required from day one.

## Product Vision

- **Success means:** Users log consistently enough that patterns emerge — reducing asthma attacks and improving medication adherence
- **Bigger picture:** Start personal, grow into a public product for anyone managing asthma
- **Not optimising for:** Complex AI/ML, real-time collaboration, social features, monetisation (v1)

## Requirements

### Validated

(None yet — ship to validate)

### Active

<!-- Milestone 1 scope -->

- [ ] User can create an account and log in securely
- [ ] User can log asthma symptoms (type, severity, timestamp, optional notes)
- [ ] User can view a timeline of past symptom logs
- [ ] User can record peak flow readings manually
- [ ] User can set their personal best peak flow value
- [ ] System automatically calculates and displays zone (Green / Yellow / Red) per reading
- [ ] User can view peak flow trends over time

### Out of Scope

- Medication management — Milestone 2
- Trigger tracking — Milestone 2
- Dashboard — Milestone 2
- Environmental API integrations — Milestone 3
- Reports (PDF/CSV export) — Milestone 3
- Caregiver accounts and shared monitoring — Milestone 4
- Analytics and advanced insights — Milestone 4
- Smart inhaler integration — Future
- Telehealth integration — Future
- Community features — Future

## Context

- App already scaffolded: `rails new asthma-buddy -d sqlite3 -j importmap --css=none --skip-jbuilder`
- SQLite in WAL mode for concurrency
- PWA capability planned (Service Workers, Web App Manifest, offline symptom logging)
- Lexxy rich text editor (Basecamp) for user notes
- UK GDPR + Data Protection Act 2018 compliance required
- WCAG 2.2 AA accessibility target

## Constraints

- **Stack**: Rails 8 Omakase — ERB, Turbo, Stimulus, Vanilla CSS, no heavy frontend frameworks
- **Database**: SQLite (WAL mode) — PostgreSQL only if scaling demands it
- **Auth**: Rails 8 built-in auth generator (`has_secure_password`) — no Devise
- **Jobs**: Solid Queue — no Redis/Sidekiq
- **Deployment**: Kamal on VPS (Hetzner)
- **Compliance**: UK GDPR, Data Protection Act 2018 — encrypted sensitive data, role-based access control
- **Accessibility**: WCAG 2.2 AA — keyboard navigation, screen reader compatible
- **Performance**: Page loads under 2 seconds

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Multi-user isolation from day 1 | App starts personal but opens to public — retro-fitting tenancy is painful | — Pending |
| SQLite over PostgreSQL | Simple deployment, sufficient for expected scale, WAL mode handles concurrency | — Pending |
| Rails 8 auth generator over Devise | Rails built-in covers all v1 auth needs with zero external dependencies | — Pending |
| Lexxy for rich text | Basecamp's editor, aligns with Rails Omakase philosophy | — Pending |

---
*Last updated: 2026-03-06 after initialization*
