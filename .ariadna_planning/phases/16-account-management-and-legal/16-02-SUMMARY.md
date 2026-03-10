---
phase: 16-account-management-and-legal
plan: "02"
subsystem: ui
tags: [rails, erb, gdpr, uk-gdpr, legal, privacy, terms, health-data, special-category]

# Dependency graph
requires:
  - phase: 16-account-management-and-legal
    provides: "PagesController with /terms and /privacy routes already registered; footer links already in layout"
provides:
  - "Substantive UK GDPR-compliant Terms of Service with 10 sections covering eligibility, acceptable use, health data disclaimer, termination, governing law"
  - "Substantive UK GDPR + DPA 2018 Privacy Policy covering special category health data, lawful bases, all 7 UK GDPR rights, ICO complaints route, cookies"
affects:
  - 16-account-management-and-legal
  - public launch readiness

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Static legal pages: ERB views with section-card wrapper, page-header div, pages-updated class, back link at bottom"
    - "Date display in legal pages: Date.today.strftime('%B %-d, %Y') for auto-updating Last Updated line"

key-files:
  created: []
  modified:
    - app/views/pages/terms.html.erb
    - app/views/pages/privacy.html.erb

key-decisions:
  - "All 10 sections use <h2> headings (not numbered in HTML) — numbers added as text within section titles for readability and SEO"
  - "Acceptable use section uses <ul> list — more scannable than a single dense paragraph for legal review"
  - "Privacy Policy uses <ul> for GDPR rights list to match UK GDPR documentation conventions"
  - "Session cookie explanation references PECR (Privacy and Electronic Communications Regulations) — correct UK law for cookie consent exemptions, not just GDPR"
  - "14-day advance notice for material changes stated explicitly in both Terms and Privacy — creates a concrete commitment"
  - "ICO contact details (phone number 0303 123 1113, ico.org.uk) included verbatim — gives users a real actionable complaints path"

patterns-established:
  - "Legal page pattern: content_for :title → page-header div → section-card div → back link"

requirements_covered:
  - id: "LEGAL-01"
    description: "Terms of Service page with UK GDPR-appropriate content"
    evidence: "app/views/pages/terms.html.erb"
  - id: "LEGAL-02"
    description: "Privacy Policy with UK GDPR + DPA 2018 compliance for health data app"
    evidence: "app/views/pages/privacy.html.erb"

# Metrics
duration: 8min
completed: 2026-03-10
---

# Phase 16 Plan 02: Terms of Service and Privacy Policy Summary

**UK GDPR-compliant Terms of Service (10 sections) and Privacy Policy (10 sections) with special category health data handling, all 7 UK GDPR rights, lawful basis declarations, and ICO complaints route — replacing minimal stubs with replace-ready legal content.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-03-10T00:00:00Z
- **Completed:** 2026-03-10T00:08:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Terms of Service enriched with 10 substantive sections: About (not a medical device), Eligibility (16+ UK GDPR threshold), Account security, Acceptable use (bullet list), Health data disclaimer, Service availability (best-efforts/no SLA), Termination (Settings page deletion), Changes (14-day advance notice), Governing law (England and Wales), Contact (legal@asthmabuddy.app)
- Privacy Policy enriched with 10 substantive sections: Who we are (data controller), What we collect (account + special category health data + server logs), Lawful basis (contract, explicit consent Art. 9(2)(a), legitimate interests), Special category health data handling, Storage (encrypted UK/EEA, bcrypt passwords), Retention (30-day erasure on deletion), All 7 UK GDPR rights (access, rectification, erasure, restriction, portability, objection, consent withdrawal), Cookies (session-only, PECR exemption), Changes (14-day notice), Contact + ICO complaints route
- Footer links to both pages already present on all authenticated and unauthenticated layouts — no layout changes required

## Task Commits

Each task was committed atomically:

1. **Task 1: Enrich Terms of Service page** - `be28ae2` (feat)
2. **Task 2: Enrich Privacy Policy page** - `af0c09c` (feat)

**Plan metadata:** (see below — final docs commit)

## Files Created/Modified
- `app/views/pages/terms.html.erb` - Terms of Service: 10 sections, UK GDPR eligibility age, health data disclaimer, governing law England and Wales, contact legal@asthmabuddy.app
- `app/views/pages/privacy.html.erb` - Privacy Policy: special category health data (Art. 9), three lawful bases, 7 UK GDPR rights enumerated, ICO complaints route, PECR cookie exemption

## Decisions Made
- Session cookie references PECR (correct UK law for cookie consent exemptions), not just GDPR — ICO guidance requires this distinction for essential cookies
- ICO phone number and URL included verbatim to give users a genuine, actionable complaints path
- 14-day advance email notice for material changes stated explicitly in both documents — creates a concrete enforceable commitment

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Terms and Privacy pages are fully populated with replace-ready legal content
- Both pages accessible unauthenticated (GET /terms, GET /privacy return 200)
- Footer links to both pages present on all layouts (verified — both authenticated and unauthenticated footers)
- Legal content ready for solicitor review before public launch
- Phase 16-03 (Cookie Notice Banner) may reference privacy_path — routes confirmed working

---
*Phase: 16-account-management-and-legal*
*Completed: 2026-03-10*
