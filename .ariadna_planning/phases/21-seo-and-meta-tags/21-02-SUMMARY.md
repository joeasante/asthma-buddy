---
phase: 21-seo-and-meta-tags
plan: 02
subsystem: ui
tags: [rails, erb, seo, meta-tags, titles, authenticated-pages]

# Dependency graph
requires:
  - phase: 21-01
    provides: "Meta description yield slot in application layout (yield :meta_description)"
provides:
  - "All 21 authenticated page titles end with ' — Asthma Buddy'"
  - "All 21 authenticated pages have a unique content_for :meta_description block"
affects:
  - 21-03

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "content_for :title pattern: 'Page Name — Asthma Buddy' for all authenticated pages"
    - "content_for :meta_description on line 2 of every authenticated view, immediately after title"

key-files:
  created: []
  modified:
    - app/views/dashboard/index.html.erb
    - app/views/profiles/show.html.erb
    - app/views/notifications/index.html.erb
    - app/views/settings/show.html.erb
    - app/views/symptom_logs/index.html.erb
    - app/views/symptom_logs/new.html.erb
    - app/views/symptom_logs/show.html.erb
    - app/views/symptom_logs/edit.html.erb
    - app/views/peak_flow_readings/index.html.erb
    - app/views/peak_flow_readings/new.html.erb
    - app/views/peak_flow_readings/show.html.erb
    - app/views/peak_flow_readings/edit.html.erb
    - app/views/health_events/index.html.erb
    - app/views/health_events/new.html.erb
    - app/views/health_events/show.html.erb
    - app/views/health_events/edit.html.erb
    - app/views/settings/medications/index.html.erb
    - app/views/settings/medications/new.html.erb
    - app/views/settings/medications/edit.html.erb
    - app/views/preventer_history/index.html.erb
    - app/views/reliever_usage/index.html.erb

key-decisions:
  - "symptom_logs/show.html.erb title changed from 'Symptoms Log' to 'Symptom Entry' — more accurately describes the page (a single entry, not the log list)"
  - "Medications pages corrected from '— Settings' suffix to '— Asthma Buddy' — brand suffix is the established pattern, not the parent section name"
  - "All title casing normalised: capitalise all principal words (e.g. 'Log a Symptom', 'Record a Reading', 'Edit Medical Event')"

patterns-established:
  - "Authenticated title pattern: content_for :title on line 1, content_for :meta_description on line 2 — consistent position across all 21 pages"

requirements_covered: []

# Metrics
duration: 5min
completed: 2026-03-12
---

# Phase 21 Plan 02: Authenticated Page Titles and Meta Descriptions Summary

**Fixed all 21 authenticated page titles to 'Page Name — Asthma Buddy' and added unique, accurate meta description blocks to every authenticated view.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-12T15:57:24Z
- **Completed:** 2026-03-12T16:02:00Z
- **Tasks:** 2
- **Files modified:** 21

## Accomplishments
- All 21 authenticated view files now have titles ending with ' — Asthma Buddy'
- Medications pages no longer use the incorrect '— Settings' suffix
- symptom_logs/show.html.erb title corrected from 'Symptoms Log' to 'Symptom Entry'
- All 21 pages have a unique, page-specific `content_for :meta_description` block on line 2
- 483 integration tests passing, 0 regressions after both tasks

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix titles for all 21 authenticated pages** - `5037a98` (feat)
2. **Task 2: Add meta descriptions to all 21 authenticated pages** - `2fcd12c` (feat)

**Plan metadata:** (docs commit — see below)

## Files Created/Modified
- `app/views/dashboard/index.html.erb` - Title + meta description
- `app/views/profiles/show.html.erb` - Title + meta description
- `app/views/notifications/index.html.erb` - Title + meta description
- `app/views/settings/show.html.erb` - Title + meta description
- `app/views/symptom_logs/index.html.erb` - Title + meta description
- `app/views/symptom_logs/new.html.erb` - Title + meta description
- `app/views/symptom_logs/show.html.erb` - Title corrected to "Symptom Entry" + meta description
- `app/views/symptom_logs/edit.html.erb` - Title + meta description
- `app/views/peak_flow_readings/index.html.erb` - Title + meta description
- `app/views/peak_flow_readings/new.html.erb` - Title + meta description
- `app/views/peak_flow_readings/show.html.erb` - Title + meta description
- `app/views/peak_flow_readings/edit.html.erb` - Title + meta description
- `app/views/health_events/index.html.erb` - Title + meta description
- `app/views/health_events/new.html.erb` - Title + meta description
- `app/views/health_events/show.html.erb` - Title + meta description
- `app/views/health_events/edit.html.erb` - Title + meta description
- `app/views/settings/medications/index.html.erb` - Title corrected from "— Settings" + meta description
- `app/views/settings/medications/new.html.erb` - Title corrected from "— Settings" + meta description
- `app/views/settings/medications/edit.html.erb` - Title corrected from "— Settings" (preserves @medication.name interpolation) + meta description
- `app/views/preventer_history/index.html.erb` - Title + meta description
- `app/views/reliever_usage/index.html.erb` - Title + meta description

## Decisions Made
- `symptom_logs/show.html.erb` title changed from 'Symptoms Log' to 'Symptom Entry' — a show view displays a single entry, not the list; the list is the index view
- Medications pages corrected from '— Settings' to '— Asthma Buddy' — brand suffix is the pattern; sub-section names like "Settings" don't belong in the title
- Title casing normalised to capitalise all principal words throughout

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Infrastructure and all authenticated page titles/descriptions are ready for 21-03 (public/unauthenticated pages)
- No blockers

---
*Phase: 21-seo-and-meta-tags*
*Completed: 2026-03-12*

## Self-Check: PASSED

- app/views/dashboard/index.html.erb — FOUND
- app/views/settings/medications/edit.html.erb — FOUND
- app/views/reliever_usage/index.html.erb — FOUND
- .ariadna_planning/phases/21-seo-and-meta-tags/21-02-SUMMARY.md — FOUND
- Commit 5037a98 — FOUND
- Commit 2fcd12c — FOUND
