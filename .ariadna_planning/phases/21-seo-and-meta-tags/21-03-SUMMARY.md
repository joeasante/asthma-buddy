---
phase: 21-seo-and-meta-tags
plan: 03
subsystem: ui
tags: [rails, erb, seo, meta-tags, auth, onboarding, legal]

# Dependency graph
requires:
  - 21-01
provides:
  - "Meta descriptions on all 7 public auth/legal pages (sessions, registrations, email_verifications, passwords x2, privacy, terms)"
  - "Meta description on onboarding wizard page"
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "content_for :meta_description on line 2 of every public/onboarding view — consistent placement immediately after title declaration"

key-files:
  created: []
  modified:
    - app/views/sessions/new.html.erb
    - app/views/registrations/new.html.erb
    - app/views/email_verifications/new.html.erb
    - app/views/passwords/new.html.erb
    - app/views/passwords/edit.html.erb
    - app/views/pages/privacy.html.erb
    - app/views/pages/terms.html.erb
    - app/views/onboarding/show.html.erb

key-decisions:
  - "Home page (home/index.html.erb) deliberately left untouched — it uses content_for :head for its existing description; no duplication"
  - "Onboarding layout already had yield(:meta_description) slot from 21-01; no layout changes needed"

# Metrics
duration: 4min
completed: 2026-03-12
---

# Phase 21 Plan 03: Public and Onboarding Page Meta Descriptions Summary

**Added concise, action-oriented `content_for :meta_description` blocks to all 7 public auth/legal pages and the onboarding wizard — completing meta description coverage across the entire app alongside plan 21-02.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-12T15:55:00Z
- **Completed:** 2026-03-12T15:58:31Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- All 7 public auth/legal pages (sessions/new, registrations/new, email_verifications/new, passwords/new, passwords/edit, pages/privacy, pages/terms) now have a `content_for :meta_description` block on line 2
- Onboarding wizard page (onboarding/show) has its meta description on line 2, routed through the onboarding layout's existing yield slot
- Home page is untouched — it uses `content_for :head` for its description, not `content_for :meta_description`
- 483 tests pass with 0 failures after both tasks — no regressions

## Task Commits

Each task was committed atomically:

1. **Task 1: Add meta descriptions to public auth and legal pages** - `0d7d466` (feat)
2. **Task 2: Add meta description to onboarding page** - `ec302b1` (feat)

## Files Created/Modified

- `app/views/sessions/new.html.erb` - Added meta description line 2: sign-in action description
- `app/views/registrations/new.html.erb` - Added meta description line 2: account creation description
- `app/views/email_verifications/new.html.erb` - Added meta description line 2: inbox verification description
- `app/views/passwords/new.html.erb` - Added meta description line 2: password reset request description
- `app/views/passwords/edit.html.erb` - Added meta description line 2: new password selection description
- `app/views/pages/privacy.html.erb` - Added meta description line 2: UK GDPR privacy policy description
- `app/views/pages/terms.html.erb` - Added meta description line 2: terms of service description
- `app/views/onboarding/show.html.erb` - Added meta description line 2: setup wizard description

## Decisions Made

- Home page left deliberately untouched — `home/index.html.erb` uses `content_for :head` for its description, not `:meta_description`. No duplication or conflict.
- Onboarding layout already had the yield slot from plan 21-01 — no layout changes needed for Task 2.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Coverage Summary

Combined with plan 21-02 (authenticated pages) and the existing home page description:
- This plan: 8 public/onboarding pages
- Plan 21-02: authenticated app pages
- Home page: existing via `:head` block
- Total app coverage: complete

---
*Phase: 21-seo-and-meta-tags*
*Completed: 2026-03-12*

## Self-Check: PASSED

- app/views/sessions/new.html.erb — FOUND
- app/views/registrations/new.html.erb — FOUND
- app/views/email_verifications/new.html.erb — FOUND
- app/views/passwords/new.html.erb — FOUND
- app/views/passwords/edit.html.erb — FOUND
- app/views/pages/privacy.html.erb — FOUND
- app/views/pages/terms.html.erb — FOUND
- app/views/onboarding/show.html.erb — FOUND
- Commit 0d7d466 — FOUND
- Commit ec302b1 — FOUND
