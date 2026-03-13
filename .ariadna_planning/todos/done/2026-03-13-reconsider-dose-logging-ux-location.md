---
created: 2026-03-13T08:02:53Z
title: Reconsider dose logging UX location
area: ui
files:
  - app/controllers/settings/dose_logs_controller.rb
  - app/views/settings/medications/
---

## Problem

Dose logging currently lives inside Settings under each medication card. Settings is the right home for managing medications (add, edit, delete, refill) but the wrong home for day-to-day activity like logging a dose. Users expect Settings to be a configuration area, not an operational one. Having dose logging buried there creates a UX mismatch — it makes the daily habit of logging doses feel like a settings task rather than a core app action.

Surfaced during Phase 22 UAT when user questioned why dose logging is in Settings.

## Solution

Move dose logging entry point to the dashboard or a dedicated logging flow. Options:
- Log dose button/form directly on the dashboard (quick-log from the preventer adherence card or reliever card)
- A dedicated `/log` or `/doses/new` flow accessible from the dashboard and nav
- Keep Settings as read-only medication management; remove create/destroy dose log actions from Settings::DoseLogsController

TBD — requires design decision before planning.
