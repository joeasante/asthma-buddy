# Asthma Buddy — Testing Plan

A systematic checklist for verifying all features of the app. Work through each section
top to bottom. Mark each item `[x]` as you go. Re-run the full checklist after any
significant code change.

---

## How to use this document

- **Smoke test** — run Section 1–3 only (15–20 min). Use after any deploy.
- **Full regression** — run all sections (60–90 min). Use after a new feature ships.
- **Feature-specific** — run only the section for the feature you changed.

---

## Section 1 — Authentication

### Registration

- [ ] Register with a valid email and password (≥8 characters) — lands on email verification page
- [ ] Register with an already-used email — shows "has already been taken" error
- [ ] Register with a password shorter than 8 characters — shows validation error
- [ ] Register with a blank email — shows validation error
- [ ] Register with a malformed email (e.g. `foo@`) — shows validation error
- [ ] After registering, a verification email arrives within a few seconds

### Email Verification

- [ ] Click the link in the verification email — account marked as verified, redirected to onboarding
- [ ] Try to visit the dashboard without verifying email — redirected to verification notice
- [ ] Request a new verification email via the "resend" link — new email arrives
- [ ] Use an expired verification link (tokens expire after 24h) — shows "link has expired" message
- [ ] Use the same verification link twice — handled gracefully (no crash)

### Login / Logout

- [ ] Log in with correct credentials — reaches dashboard (or onboarding if incomplete)
- [ ] Log in with wrong password — shows error, does not log in
- [ ] Log in with unregistered email — shows error
- [ ] Log in with blank fields — shows validation errors
- [ ] Log out — session ends, visiting `/dashboard` redirects to login

### Password Reset

- [ ] Request reset for a registered email — email arrives
- [ ] Request reset for an unknown email — no error exposed (silent, for security)
- [ ] Click reset link and set a new password (≥8 chars) — password updated, can log in
- [ ] Try to use an expired reset link (tokens expire after 1h) — shows expired message
- [ ] Try to use a reset link after password has already been reset — link is invalidated

---

## Section 2 — Onboarding

### Step 1 — Personal Best

- [ ] Submit a valid personal best (e.g. 450 L/min) — advances to step 2
- [ ] Submit 100 — accepted (lower boundary)
- [ ] Submit 900 — accepted (upper boundary)
- [ ] Submit 99 — shows validation error
- [ ] Submit 901 — shows validation error
- [ ] Submit blank — shows validation error
- [ ] Submit 0 or a negative number — shows validation error
- [ ] Click "Skip" — advances to step 2 without saving a personal best
- [ ] After completing step 1, navigate back to `/onboarding/step/1` — redirected away (already done)

### Step 2 — First Medication

- [ ] Submit with a valid medication name, type, dose, count — redirected to dashboard with welcome notice
- [ ] Submit with a blank medication name — shows validation error
- [ ] Submit with 0 puffs — shows validation error
- [ ] Submit with a negative dose count — shows validation error
- [ ] Click "Skip" — redirected to dashboard, notice says "complete setup any time from Settings"
- [ ] Skip both steps — dashboard is accessible; no personal best or medication exists
- [ ] After full onboarding, visiting `/onboarding/step/1` — redirected to dashboard

---

## Section 3 — Dashboard

### Page Load

- [ ] Dashboard loads without errors after onboarding
- [ ] Dashboard shows correct week start (Monday) for stats
- [ ] "Week's readings" count matches the number of peak flow readings entered this week
- [ ] "Week's symptoms" count matches symptom logs this week
- [ ] "Weekly average" shows the correct average of this week's readings
- [ ] Weekly average has correct zone colour (green/yellow/red) based on personal best %
- [ ] Dashboard with zero data (fresh account, skipped onboarding) — empty states show, no errors

### Peak Flow Chart

- [ ] 7-day chart renders with correct dates on the x-axis (Mon through today)
- [ ] AM and PM readings render as separate points on the correct day
- [ ] Chart uses correct zone colours (green/yellow/red) per reading
- [ ] Health event markers appear on the correct date
- [ ] Ongoing health events (started before this week) appear in the "Active" strip, not on the chart
- [ ] Chart with no data — shows empty state, no JS errors in console

### Cards and Sections

- [ ] "Recent readings" section shows the last 3 days of readings, grouped by date
- [ ] "Recent symptoms" section shows the last 4 symptom logs
- [ ] "Recent health events" shows the last 3 events
- [ ] "Low stock" section appears only when a medication is genuinely low
- [ ] "Low stock" section is absent when all medications have sufficient supply
- [ ] Today's preventer adherence section shows correct taken/expected dose count
- [ ] Active illness banner appears when there is an ongoing illness event
- [ ] Active illness banner is absent when no illness is ongoing

### Today's Doses (Reliever Medications)

- [ ] Reliever medications appear in the quick-log section
- [ ] Logging a dose from the dashboard saves a DoseLog and updates the count
- [ ] If logging triggers low stock, a notification is created

---

## Section 4 — Peak Flow Readings

### Creating a Reading

- [ ] Create a morning reading with a value of 1 — accepted (lower boundary)
- [ ] Create a reading with a value of 900 — accepted (upper boundary)
- [ ] Create a reading with a value of 0 — validation error "must be between 1 and 900 L/min"
- [ ] Create a reading with a value of 901 — validation error
- [ ] Create a reading with a blank value — validation error
- [ ] Create a reading with a non-numeric value (e.g. "abc") — validation error
- [ ] Create a morning reading — time of day saved as "morning"
- [ ] Create an evening reading — time of day saved as "evening"
- [ ] Try to create a second morning reading on the same day — error "You already have a morning reading for today"
- [ ] Try to create a second evening reading on the same day — same duplicate error
- [ ] Create reading dated exactly 1 year ago today — accepted (boundary)
- [ ] Create reading dated more than 1 year ago — validation error "cannot be more than 1 year in the past"
- [ ] Create reading with a future timestamp (more than 5 minutes ahead) — validation error "cannot be in the future"

### Zone Classification

- [ ] Reading at exactly 80% of personal best — zone is green
- [ ] Reading at exactly 50% of personal best — zone is yellow
- [ ] Reading at 79% of personal best — zone is yellow
- [ ] Reading at 49% of personal best — zone is red
- [ ] Reading with no personal best on record — zone is blank (no zone assigned)
- [ ] Zone percentage shown in reading detail matches the calculation

### Editing a Reading

- [ ] Edit a reading's value — saved, zone recalculated and updated
- [ ] Edit a reading's time of day — saved correctly
- [ ] Edit to create a duplicate session — blocked by validation

### Deleting a Reading

- [ ] Delete a reading — it disappears from the list immediately (Turbo Stream)
- [ ] Delete the reading that was the "last reading" on the dashboard — dashboard updates correctly on next load

### Filtering and Pagination

- [ ] Filter by date range (start date only) — only shows readings on/after that date
- [ ] Filter by date range (end date only) — only shows readings on/before that date
- [ ] Filter by both start and end date — correct subset returned
- [ ] Clear filter — returns full list
- [ ] Pagination: with more than 25 readings, page 2 link appears and works
- [ ] Pagination: navigating to a page beyond the last — clamped to last page, no error

---

## Section 5 — Symptom Logs

### Creating a Log

- [ ] Create a log with every field filled in — saved successfully
- [ ] Create a log with only required fields (symptom type, severity, recorded_at) — accepted
- [ ] Try to create a log with no symptom type — validation error
- [ ] Try to create a log with no severity — validation error
- [ ] Try to create a log with no date — validation error
- [ ] Select multiple triggers — all saved and displayed correctly
- [ ] Add rich text notes — saved and rendered as HTML
- [ ] Add notes with formatting (bold, list) — rendered correctly

### Triggers

- [ ] Select "cold air" trigger — saved
- [ ] Select "exercise" trigger — saved
- [ ] All 13 predefined triggers appear in the form
- [ ] A log with no triggers selected — saved with empty trigger list, no error

### Editing and Deleting

- [ ] Edit a symptom log — changes saved, redirected to log detail
- [ ] Delete a symptom log — removed from list (Turbo Stream), count in page header updates

### Filtering and Pagination

- [ ] Filter by date range — correct results
- [ ] Filter with start date after all existing logs — returns empty state, not an error
- [ ] Pagination works with more than 25 logs

### Trend Bar

- [ ] Trend bar at the top of the list shows correct counts for mild / moderate / severe
- [ ] Trend bar updates after adding or deleting a log

---

## Section 6 — Health Events (Medical History)

### Creating an Event

- [ ] Create a "GP appointment" — point-in-time type, no end date field shown
- [ ] Create a "Medication change" — point-in-time type, no end date field
- [ ] Create an "Illness" with a start and end date — duration saved
- [ ] Create a "Hospital visit" with only a start date — saved as ongoing
- [ ] Create an "Other" event — saved
- [ ] Try to save with no event type — validation error
- [ ] Try to save with no start date — validation error
- [ ] Create with end date before start date — validation error "must be after the start date"
- [ ] Create with end date equal to start date — validation error
- [ ] Create with a start date more than 5 minutes in the future — validation error
- [ ] Create with start date of 1899-12-31 — validation error (before 1900)
- [ ] Create with start date of 1900-01-01 — accepted (boundary)

### Duration Display

- [ ] Event with 3 days 4 hours duration shows "3d 4h"
- [ ] Event with exactly 9 days shows "9d"
- [ ] Event with 6 hours shows "6h"
- [ ] Ongoing event (no end date) shows "Ongoing" indicator

### Editing and Deleting

- [ ] Edit a health event — changes saved
- [ ] Mark an ongoing illness as ended by adding an end date — saved, dashboard banner clears
- [ ] Delete a health event — removed from list

### Dashboard Integration

- [ ] After adding an illness event (ongoing), dashboard shows the active illness banner
- [ ] After ending the illness, banner is no longer shown
- [ ] Health event appears as a marker on the dashboard 7-day chart on the correct date

---

## Section 7 — Medications

### Creating a Medication

- [ ] Create a reliever (e.g. Ventolin) with name, puffs, count, doses/day — saved
- [ ] Create a preventer with all fields — saved
- [ ] Create a combination medication — saved
- [ ] Create a tablet medication — saved
- [ ] Try to save with no name — validation error
- [ ] Try to save with a name over 100 characters — validation error
- [ ] Try to save with 0 standard puffs — validation error
- [ ] Try to save with a negative starting count — validation error
- [ ] Create a course medication with start and end dates — saved
- [ ] Create a course medication with end date before start — validation error "must be after the start date"
- [ ] Create a course medication with equal start and end date — validation error
- [ ] Try to create a course medication without start/end dates — validation errors

### Dose Logging

- [ ] Log a dose of 1 puff — DoseLog saved, remaining count decreases
- [ ] Log a dose of 2 puffs — remaining count decreases by 2
- [ ] Log 0 puffs — validation error
- [ ] Delete a dose log — remaining count increases, page updates (Turbo Stream)
- [ ] Log dose from dashboard quick-log button — same result

### Low Stock Alerts

- [ ] When remaining supply drops below 14 days, a notification is created automatically
- [ ] If a notification for that medication already exists, no duplicate is created
- [ ] Low stock badge appears on the medication card

### Refill

- [ ] Refill a medication — starting count resets to refill value, remaining count recalculates
- [ ] After refill, if stock is now sufficient, low stock status clears

### Editing and Deleting

- [ ] Edit a medication name — updated everywhere
- [ ] Edit doses per day — days of supply remaining recalculates
- [ ] Delete a medication — removed from list; associated dose logs also deleted

### Preventer History

- [ ] Navigate to Preventer History (via link on Medications settings page)
- [ ] Grid shows correct taken/missed status per day for each preventer
- [ ] Days where dose was taken are visually distinct from missed days

---

## Section 8 — Notifications

- [ ] Bell icon in nav shows unread count badge when notifications exist
- [ ] Badge is absent when all notifications are read
- [ ] Notifications page lists all notifications, newest first
- [ ] Clicking "Mark as read" on a single notification — it loses the unread style, badge count decreases
- [ ] Clicking "Mark all read" — all notifications marked read, badge clears
- [ ] Clicking the notification for a low-stock medication navigates to that medication
- [ ] Read notifications older than 90 days are pruned (test: check that pruneable scope works)
- [ ] No duplicate low-stock notification is created if one already exists for the same medication

---

## Section 9 — Profile

### Personal Details

- [ ] Update full name — saved and reflected in the header/nav
- [ ] Update full name to over 100 characters — validation error
- [ ] Clear full name (blank) — accepted (optional field)
- [ ] Update date of birth — saved
- [ ] Cannot update email address (field not present — changing email requires re-verification)

### Avatar

- [ ] Upload a JPEG avatar — saved, shown on profile page
- [ ] Upload a PNG avatar — accepted
- [ ] Upload a WebP avatar — accepted
- [ ] Upload a GIF avatar — accepted
- [ ] Upload a file larger than 5 MB — validation error
- [ ] Upload a PDF — validation error (wrong content type)
- [ ] Remove avatar — avatar cleared, default placeholder shown

### Password Change

- [ ] Change password with correct current password and valid new password (≥8 chars) — saved
- [ ] Submit wrong current password — error "is incorrect"
- [ ] Submit new password shorter than 8 characters — validation error
- [ ] Leave new password blank — profile saves without changing password (password fields ignored)

### Personal Best

- [ ] Update personal best from profile — saved, dashboard zone indicators recalculate on next load
- [ ] Submit a personal best below 100 — validation error
- [ ] Submit a personal best above 900 — validation error

---

## Section 10 — Settings

- [ ] Settings page loads at `/settings`
- [ ] Link to Medications from Settings page works
- [ ] Link to Profile from Settings page works
- [ ] "Delete account" option is present under Account Settings

### Account Deletion

- [ ] Delete account — all user data deleted, session ended, redirected to home
- [ ] After deletion, attempting to log in with old credentials fails

---

## Section 11 — Edge Cases and Error States

### Empty States

- [ ] Peak flow list with zero readings — empty state message shown, no errors
- [ ] Symptom log list with zero entries — empty state message shown
- [ ] Health events list with zero events — empty state message shown
- [ ] Medications list with no medications — empty state message shown
- [ ] Notifications with none — empty state shown, no badge
- [ ] Dashboard for a brand-new user — all empty states, no JS errors

### Unauthenticated Access

- [ ] Visit `/dashboard` without being logged in — redirected to login
- [ ] Visit `/peak-flow-readings` without being logged in — redirected to login
- [ ] Visit `/symptom-logs` without being logged in — redirected to login
- [ ] Visit `/medical-history` without being logged in — redirected to login
- [ ] Visit `/settings/medications` without being logged in — redirected to login
- [ ] Visit `/profile` without being logged in — redirected to login

### Data Isolation

- [ ] Create two test accounts (User A and User B)
- [ ] Log data as User A
- [ ] Log in as User B — User A's readings are not visible anywhere
- [ ] Try to access User A's reading URL directly as User B (e.g. `/peak-flow-readings/123`) — returns 404 or 403, not the data

### Boundary Values Summary

| Field                         | Min     | Max     | Both boundaries tested? |
|-------------------------------|---------|---------|--------------------------|
| Peak flow value               | 1       | 900     | [ ]                      |
| Personal best (onboarding)    | 100     | 900     | [ ]                      |
| Personal best (profile)       | 100     | 900     | [ ]                      |
| Medication name length        | 1 char  | 100 ch  | [ ]                      |
| Standard dose puffs           | 1       | no max  | [ ]                      |
| Starting dose count           | 0       | no max  | [ ]                      |
| Password length               | 8       | no max  | [ ]                      |
| Full name length              | 0       | 100 ch  | [ ]                      |
| Reading date (past)           | 1y ago  | now     | [ ]                      |
| Health event date (past)      | 1900    | now     | [ ]                      |
| Avatar file size              | —       | 5 MB    | [ ]                      |

### Error Page States

- [ ] Visit a non-existent URL (e.g. `/blah`) — 404 page renders, not a crash
- [ ] Simulate a server error — 500 page renders cleanly

---

## Section 12 — Cross-Device and Cross-Browser

### Browsers to test (desktop)

- [ ] Safari (macOS) — primary browser for your likely user base
- [ ] Chrome (macOS or Windows)
- [ ] Firefox

### Devices to test

- [ ] iPhone (Safari, iOS) — most important: app is a health tracker, likely used on mobile
- [ ] iPad (Safari, iPadOS) — check layout at tablet width
- [ ] Android phone (Chrome) — at least one test

### What to check on each device/browser

For each combination above, run through this list:

- [ ] Dashboard renders correctly — chart visible, no overlapping elements
- [ ] Navigation (bottom nav on mobile) — all links work, active state correct
- [ ] Peak flow form — keyboard type is numeric for the value field
- [ ] Symptom log form — trigger checkboxes are tappable
- [ ] Medication dose logging — button responds on tap (not just click)
- [ ] Rich text editor (notes fields) — renders and allows input
- [ ] Avatar upload — file picker works on mobile
- [ ] Date pickers — native date inputs work on iOS/Android
- [ ] Turbo Stream updates — "Mark as read" notification updates without a full page reload
- [ ] Scroll behaviour — long lists scroll smoothly, no horizontal overflow
- [ ] Fonts and icons load correctly — no missing glyphs or broken icon display

### Responsive Layout Breakpoints

- [ ] At 375px width (iPhone SE) — no horizontal scroll, no broken layouts
- [ ] At 768px width (tablet portrait) — layout adapts correctly
- [ ] At 1280px width (desktop) — content has sensible max width, not stretched

---

## Section 13 — User Testing

### Who to test with

A good test involves 3–5 people who are not familiar with the app. Ideally:
- Someone with asthma (your actual target user)
- Someone who has not seen the app before
- Someone who is not particularly tech-savvy

### Setup

- Create a fresh account for the tester — do not log in for them
- Sit back and observe without helping unless they are completely stuck
- Keep a notepad to note where they pause, hesitate, or express confusion

### Tasks to give the tester (without explaining how)

Give one task at a time. Don't mention what the task is testing.

1. "Create an account and get set up."
2. "Record a peak flow reading of 420 for this morning."
3. "Log a symptom — you've been wheezing after exercise."
4. "Add your Ventolin inhaler. It has 200 doses and you take 2 puffs twice a day."
5. "Log 2 puffs of your Ventolin."
6. "You had a GP appointment yesterday. Record it."
7. "Find out what zone your last peak flow reading was in."
8. "Mark all your notifications as read."
9. "Change your profile photo."
10. "Update your peak flow personal best to 480."

### What to observe

- **Where do they pause or hesitate?** — navigation or labelling is unclear
- **Where do they click first when unsure?** — reveals expected information architecture
- **Do they notice the zone colours?** — visual communication of risk level
- **Do they understand the dashboard without explanation?** — stat cards and chart
- **Do they use the bottom navigation correctly?** — mobile nav labels are clear
- **Do they try to do something the app doesn't support?** — potential missing features
- **What terminology confuses them?** — "preventer", "reliever", "L/min", "personal best"

### Questions to ask after the session

1. "Was anything confusing or unexpected?"
2. "Did anything feel like it was missing?"
3. "What did you think the dashboard was showing you at a glance?"
4. "Did the colour coding (green/yellow/red) make sense to you without explanation?"
5. "How would you describe what this app does to someone else?"
6. "How confident do you feel that your data was saved correctly?"
7. "Is there anything you expected to be able to do but couldn't find?"

### Red flags to watch for

- Tester tries to register twice (the sign-up flow is unclear)
- Tester cannot find how to add a reading (bottom nav label not obvious)
- Tester does not notice the zone colour on readings
- Tester cannot distinguish between "symptom log" and "health event"
- Tester does not understand what "personal best" means without asthma knowledge

---

## Section 14 — Regression Testing (When New Features Ship)

### The principle

When you add a feature, you risk breaking something that already worked. The goal is to
catch regressions before users do, with the minimum effort needed.

### After every code change — Smoke Test (5 min)

Run this every time you deploy, even for small changes:

- [ ] Can log in
- [ ] Dashboard loads without errors
- [ ] Can create a peak flow reading
- [ ] Can create a symptom log
- [ ] Notifications bell shows correct count

### After a change to peak flow readings

- [ ] Full Section 4 checklist
- [ ] Dashboard chart still renders
- [ ] Zone colours still match expected thresholds

### After a change to medications or dose logs

- [ ] Full Section 7 checklist
- [ ] Low-stock notification still fires after logging a dose
- [ ] Dashboard reliever quick-log still works
- [ ] Preventer History page still loads

### After a change to notifications

- [ ] Full Section 8 checklist
- [ ] Bell badge count updates after marking read

### After a change to authentication or profile

- [ ] Full Section 1 and Section 9 checklists
- [ ] Data isolation check (Section 11 — two accounts can't see each other's data)

### After a change to the dashboard

- [ ] Full Section 3 checklist
- [ ] Check dashboard loads for a user with zero data (no crash)
- [ ] Check dashboard loads for a user with many entries (no N+1 slowness)

### After a database migration

- [ ] Run `bin/rails db:migrate` locally and verify no errors
- [ ] Run the full smoke test
- [ ] Check that existing data records still render correctly
- [ ] If a column was removed: search code for any remaining references to it

### Automated tests (run before every merge to main)

```bash
bin/rails test              # all unit and integration tests
bin/rails test:system       # Capybara browser tests
bin/rubocop                 # linting
bin/brakeman                # security scan
bin/bundler-audit check     # dependency vulnerabilities
```

If any of these fail, do not merge. Fix the failure first.

### Keeping this document current

When a new feature is added, add its checklist items to the relevant section (or create a
new section) before marking the feature as done. The checklist is only useful if it
reflects what the app actually does.
