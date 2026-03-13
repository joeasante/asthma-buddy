---
created: 2026-03-13T18:58:54Z
title: Add admin user management page
area: ui
files:
  - app/controllers/admin/base_controller.rb
  - app/views/settings/show.html.erb
  - app/models/user.rb
---

## Problem

Admins can access Mission Control Jobs via `/jobs`, but there is no in-app way to promote or demote other users to/from admin status. The only way to grant admin access to a new account is via the Rails console (`User.find_by(email_address:).update!(admin: true)`), which requires server access.

Context: `admin` boolean column was added to `users` in migration `20260313184514_add_admin_to_users.rb`. `Admin::BaseController` checks `Current.user&.admin?`. The Mission Control card in Settings is already conditionally shown to admins only.

## Solution

Build a simple admin-only users page accessible from the Mission Control card in Settings:

- Route: `GET /admin/users` (within the existing `Admin::` namespace, protected by `Admin::BaseController`)
- View: table listing all users (email, name, joined date, admin status)
- Toggle action: `PATCH /admin/users/:id/toggle_admin` — flips admin boolean, redirects back
- Guard: prevent admin from demoting themselves (so there's always at least one admin)
- Link from the Mission Control settings card (or add an "Admin" sub-nav within the jobs area)
- No full user management needed — just list + admin toggle
