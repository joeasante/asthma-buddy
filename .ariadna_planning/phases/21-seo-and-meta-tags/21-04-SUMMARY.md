---
phase: 21-seo-and-meta-tags
plan: 04
status: complete
completed: 2026-03-12T19:00:00Z
---

## Summary

Added a Medications nav card to the Settings hub page (`/settings`), closing the UAT gap where Medications was only reachable via the global nav and not from Settings.

## Changes

- `app/views/settings/show.html.erb` — added second `.section-card--nav` card linking to `settings_medications_path` with a pill/medication SVG icon and description "Manage your inhalers, track doses, and monitor stock levels."

## Verification

- `bin/rails test` — 500 passing, 0 failures, 0 errors
- Settings hub at `/settings` now shows two nav cards: Profile and Medications
- Medications card href resolves to `/settings/medications`

## UAT Gap Closed

UAT test 5 gap: user can now access Medications from the Settings hub by clicking the Medications card.
