# Asthma Buddy — UI Build Prompts

> **How to use:** When building a page, paste the **SHARED CONTEXT** section followed by the relevant **page-specific section** into Claude Code. Both together form a complete, self-contained build prompt.

---

## SHARED CONTEXT

### Role

You are a senior product designer and frontend engineer working on Asthma Buddy — a daily health companion PWA built in Ruby on Rails with ERB templates, Stimulus controllers, and Turbo Streams. Your job is to build production-grade UI that is calm, trustworthy, and easy to use for people who may be logging symptoms while fatigued or symptomatic.

**DESIGN-SYSTEM.md is your single source of truth.** Read it before writing any code. Every visual decision — colour, spacing, typography, shadow, radius, interaction — must reference a token defined there. No raw hex values anywhere except `application.css :root`.

---

### Non-Negotiable Rules

#### Colours
- Every colour must reference a CSS custom property: `color: var(--brand)` not `color: #0d9488`
- Amber warning text: always use `--severity-moderate-text` (#92400e) — never `--severity-moderate` (#d97706) which fails WCAG AA on white
- No new tokens unless genuinely required — if you add one, define it in `application.css :root` with a comment and tell me

#### Typography
- Headings: `--font-heading` (Plus Jakarta Sans), body/UI: `--font-body` (Inter)
- Base body size: 1.125rem (18px), line-height 1.6 — never go below this
- Match sizes to the type scale in DESIGN-SYSTEM.md section 1.2 — no arbitrary font sizes

#### Spacing
- Use spacing tokens (`--space-xs` through `--space-2xl`) or bare rem values
- No px values except for borders (1px, 2px) and border-radius tokens

#### Touch Targets
- Every interactive element: 44px minimum on touch devices (`pointer: coarse`)
- This includes icon-only buttons (row actions, modal close, nav icons) — use `min-width: 44px; min-height: 44px; display: inline-flex; align-items: center; justify-content: center`
- Bottom nav tabs: maintain 52px min-height
- Checkbox and radio labels: `min-height: 44px` on the wrapping `<label>`

#### Layout
- No sidebar — top nav on desktop, fixed bottom nav on mobile (max-width: 768px)
- Content max-width: 860px, centred
- Mobile-first. Every page must work at 375px (bottom nav), 768px (tablet), and 1280px (top nav)
- Safe-area insets on bottom nav: `padding-bottom: env(safe-area-inset-bottom)`

#### Components
- Reuse existing classes: `.section-card`, `.btn-primary`, `.btn-secondary`, `.btn-cancel`, `.btn-delete`, `.field`, `.field-error`, `.flash`, `.page-header`, `.data-table`, `.table-wrap`, `.pagination-btn`, `.medication-badge`, `.bottom-nav`, `.auth-card`
- Never duplicate a component that already exists — if you need a variation, use a BEM modifier (e.g. `.section-card--highlighted`)
- Repeated structural HTML must be an ERB partial, not copy-pasted markup

#### Forms
- Label always above the input, never placeholder-as-label
- Inline field error (`.field-error`) immediately after the `<input>`, inside `.field`
- Focus: `border-color: var(--teal-500); box-shadow: 0 0 0 3px var(--brand-ring)`
- Error border: `var(--error-border)`
- No browser native validation popups — validate server-side, render errors in the DOM
- Minimum input height: 44px

#### Loading States
- Skeleton screens for data — not spinners
- Skeleton: grey rounded blocks at the approximate size of the content they replace, using the `.skeleton` class defined in DESIGN-SYSTEM.md section 2.11
- Inline button loading: replace button text with a subtle spinner, disable the button, do not skeleton the whole page

#### Empty States
- Never leave a blank content area
- Structure: centred icon (SVG, 48px, `--text-4`) + headline (`--text`, h3) + one-line description (`--text-3`) + CTA button if an action is available
- Copy must be specific to the context — not generic "No data found"
- Use the `.empty-state` class defined in DESIGN-SYSTEM.md section 2.10

#### Destructive Actions
- Every delete or irreversible action must open the `<dialog>` confirm modal via `confirm_controller.js`
- Never fire a DELETE request from a direct button click
- Account deletion dialog: requires user to type their email address to confirm

#### Interactions
- Hover, focus (`:focus-visible`), active, and disabled states on every interactive element
- Transitions: `150ms ease-out` for most interactions, `300ms ease-out` for modals and drawers
- Respect `@media (prefers-reduced-motion: reduce)` — disable transforms and transitions, keep opacity fades only

#### Turbo & Stimulus
- Form submissions: use Turbo Stream responses (`create.turbo_stream.erb`, `update.turbo_stream.erb`, `destroy.turbo_stream.erb`)
- Success feedback after a mutation: dispatch a `toast:show` CustomEvent with `{ message, variant }` from the Turbo Stream response — do not use a full page flash for inline actions
- Interactive behaviour (toggles, charts, dropdowns, now-shortcuts): wire a Stimulus controller — no inline JavaScript in ERB templates

#### Dark Mode
- Do not add any dark-mode-specific component classes
- If the component includes a Chart.js chart: read `--text-3` and `--border` via `getComputedStyle` in the Stimulus controller and pass them as chart colours — chart libraries do not read CSS variables automatically

#### Accessibility
- All form inputs have an associated `<label for="">` — no exceptions
- Icon-only buttons: `aria-label` describing the action
- Images: meaningful `alt` text, decorative images `alt=""`
- Focus indicators always visible — never `outline: none` without a replacement
- Contrast: 4.5:1 minimum for body text, 3:1 for UI components

#### CSS Organisation
Within each CSS file, follow this order:
1. Section comment block
2. Container / layout rules
3. Child element rules (top to bottom, structural order)
4. Modifier classes (`--variant`)
5. State classes (`:hover`, `:focus`, `:disabled`)
6. Responsive overrides (`@media` blocks, smallest breakpoint first)
7. `@media (prefers-reduced-motion: reduce)` overrides

#### File Naming
- CSS: `snake_case.css` → `peak_flow.css`
- CSS classes: `kebab-case` → `.section-card`
- CSS custom properties: `--kebab-case` → `--brand`
- ERB partials: `_snake_case.html.erb` → `_timeline_row.html.erb`
- Stimulus controllers: `snake_case_controller.js` → `chart_controller.js`
- Turbo Stream partials: named after the action → `create.turbo_stream.erb`

---

### Pre-Flight Checklist

Before marking this done, verify every item:

- [ ] All colours reference CSS custom properties — zero raw hex values outside `:root`
- [ ] Amber text uses `--severity-moderate-text`, never `--severity-moderate`
- [ ] All spacing uses tokens or bare rem — no px except borders
- [ ] Typography matches the type scale — no arbitrary sizes
- [ ] Every interactive element has hover, focus (`:focus-visible`), active, and disabled states
- [ ] All touch targets are 44px minimum, including icon-only buttons
- [ ] Form fields: label above, `.field-error` below, focus ring correct
- [ ] Loading state is a skeleton screen, not a spinner
- [ ] Empty state has icon + headline + description + CTA
- [ ] Every destructive action routes through the `<dialog>` confirm modal
- [ ] Mobile layout works at 375px with bottom nav
- [ ] Tablet layout works at 768px
- [ ] Desktop layout works at 1280px with top nav
- [ ] No lorem ipsum — realistic sample data matching the health app context
- [ ] Repeated HTML is a partial
- [ ] Interactive behaviour uses a Stimulus controller — no inline JS
- [ ] Turbo Stream responses used for form mutations
- [ ] Charts pass CSS variable colours via `getComputedStyle` in the controller
- [ ] `prefers-reduced-motion` override present if any transforms or transitions are used
- [ ] All images have meaningful `alt` text
- [ ] All icon-only buttons have `aria-label`
- [ ] No new CSS tokens added without defining them in `application.css :root` with a comment

---

### Deliver

When complete, tell me:

1. **Files created or modified** — full paths
2. **New CSS tokens added** — name, value, and why
3. **Design decisions not covered by DESIGN-SYSTEM.md** — what you encountered and what you chose
4. **Anything that needs a follow-up decision from me** — flag it clearly, do not silently guess

If item 3 or 4 contains anything substantive, I will update DESIGN-SYSTEM.md before we build the next page.

---
---

## Page Prompts

> Paste SHARED CONTEXT above + the relevant section below into Claude Code.

---

## 1. Home / Landing Page

### What I Need Built

**Page / component:** Public landing page at `GET /`

**Requirements from DESIGN-SYSTEM.md section 6.1:**
- Purpose: App introduction; drive sign-up or sign-in. Authenticated users are redirected to dashboard.
- Key components: `.home-hero` (centred, max-width 560px), `.home-features` auto-fit grid, `.btn-primary` ("Get started free" → `/registrations/new`), `.btn-secondary` ("Sign in" → `/session/new`), top nav with Sign in / Get started links (no bottom nav on public pages).
- No authenticated user features — no bottom nav, no avatar menu.

**Additional context:**
- Files to modify: `app/views/home/index.html.erb`, `app/assets/stylesheets/application.css` (home-specific classes already exist: `.home-hero`, `.home-features`, `.home-feature`).
- The existing styles use a plain feature-card grid. Redesign to feel more polished: the hero should have a large teal gradient accent behind the headline text (use `--brand-light` as a soft wash, no hard gradients), a brief value proposition subtitle, and the two CTA buttons side-by-side on a single line (stacked on mobile).
- Feature cards: four cards showcasing Symptoms, Peak Flow, Medications, and Dashboard. Each card: a relevant SVG icon (24px, `--brand`), a bold short headline, and a one-sentence description. Use real copy — not lorem ipsum. Example headlines: "Track symptoms instantly", "Monitor your peak flow", "Never run out of medication", "See your patterns at a glance".
- The top nav on the landing page shows the brand name on the left and two links on the right: "Sign in" (`.nav-link`) and "Get started" (`.nav-link--cta`). No user avatar.
- No footer content needed beyond the copyright line already in the layout.
- Realistic headline copy: "Breathe easier. Every day." — subtitle: "Log symptoms, track peak flow, and manage medications — all in one place built for people with asthma."
- Do not add a bottom nav for unauthenticated pages.

---

## 2. Authentication Pages

### What I Need Built

**Page / component:** Five authentication pages sharing the `.auth-card` layout:
1. Sign in — `GET /session/new`
2. Sign up / Registration — `GET /registrations/new`
3. Forgot password — `GET /passwords/new`
4. Password reset — `GET /passwords/:token/edit`
5. Email verification — `GET /email_verifications/new`

**Requirements from DESIGN-SYSTEM.md section 6.1:**
- All five use `.auth-card` (max-width 400px, centred, `--shadow-lg`).
- No bottom nav, no user avatar menu — public pages.
- Sign in: email + password fields, "Sign in" primary button (full width), forgot-password link below, sign-up link in `.auth-links`.
- Sign up: full name + email + password fields, "Create account" primary button (full width), sign-in link in `.auth-links`. After submit → redirected to email verification.
- Forgot password: email field only, "Send reset link" primary button. Post-submit: show a confirmation message in place of the form ("Check your inbox — if that email is registered, a reset link is on its way."). Never indicate whether the email exists.
- Password reset: new password + confirm password fields, "Set new password" button. Expired token state: replace form with a `.flash--alert` and a link back to forgot-password.
- Email verification: no form fields. Instructional text: "We've sent a verification email to [user email]. Click the link in that email to activate your account." Resend link: "Didn't get it? Resend the email." as a styled button (`.btn-secondary`, full width).
- Special states: flash errors on all pages for validation failures.

**Additional context:**
- Files to modify: `app/views/sessions/new.html.erb`, `app/views/registrations/new.html.erb`, `app/views/passwords/new.html.erb`, `app/views/passwords/edit.html.erb`, `app/views/email_verifications/new.html.erb`. CSS in `application.css` (`.auth-card` already exists).
- All auth pages use the same layout (`layouts/application.html.erb`) — the bottom nav partial should already guard against showing on unauthenticated pages (check `Current.user` before rendering).
- Add a teal brand mark above the card heading on every auth page — a small SVG lung/breath icon or the app name in `--font-heading` at 1.25rem, centred, `--brand` colour. This grounds the page visually.
- Password field: add a show/hide toggle button (eye icon SVG) inside the input wrapper. Wire a Stimulus controller `password_visibility_controller.js` — targets the input and toggles `type="password"` / `type="text"`. The toggle button is `aria-label="Show password"` / `aria-label="Hide password"`.
- The card `<h1>` for each page: "Sign in", "Create your account", "Reset your password", "Choose a new password", "Check your email".
- Do not add a bottom nav on any of these pages.
- The `.auth-card` already has padding, border, and shadow defined — do not duplicate those rules. Add only what is missing.

---

## 3. Onboarding Wizard

### What I Need Built

**Page / component:** Three-step onboarding wizard for new users at `GET /onboarding/step/:step` (steps 1–3)

**Requirements from DESIGN-SYSTEM.md section 6.2:**
- Purpose: Guide new users through initial setup before they reach the dashboard.
- Step 1: Set personal best peak flow value (number input, 100–900 L/min).
- Step 2: Add first medication (name, type select, standard dose puffs, doses per day — minimal required fields only, can add full details later in Settings).
- Step 3: Choose first log — two large option cards: "Log a symptom" and "Record peak flow". Selecting one navigates to the respective new-log form.
- Progress indicator: step dots at the top (3 dots, current dot `--brand`, completed dots `--severity-mild`, upcoming dots `--border-mid`).
- Each step inside a `.section-card`. "Skip this step" link (`.btn-cancel`) below every card. "Back" link on steps 2 and 3.
- Completion of step 3 (or its skip) redirects to dashboard with a `.flash--notice`: "Welcome to Asthma Buddy! You're all set."
- No bottom nav during onboarding — full-screen focused flow.

**Additional context:**
- Files to create: `app/views/onboarding/` directory with `show.html.erb` (single view, step rendered as a partial), `_step_1.html.erb`, `_step_2.html.erb`, `_step_3.html.erb`. Controller: `OnboardingController` with a `show` action reading `params[:step]`.
- CSS: create `app/assets/stylesheets/onboarding.css`.
- Progress indicator markup: `<div class="onboarding-progress">` containing three `<span class="onboarding-dot">` elements with modifiers `--active`, `--complete`, `--pending`. No labels needed on the dots.
- Step 3 option cards: full-width (mobile) / side-by-side (desktop, each ~50% width). Each card: large SVG icon centred (48px, `--brand`), bold title, one-line description. On hover: `border-color: var(--brand); box-shadow: var(--shadow-md)`. On click: navigate immediately, no confirmation needed.
- Step 3 cards are links (`<a>`) styled as `.section-card--option` — add this modifier to `onboarding.css`.
- Minimal form on step 2: just the fields needed to create a valid `Medication` record (name is required, type is required, dose fields have sensible defaults — 2 puffs standard dose, 4 puffs sick day dose, 2 doses per day). Pre-fill select to "Reliever" since that's the most common first medication for people with asthma.
- All three steps share a header: brand name centred above the progress dots, no top nav chrome.

---

## 4. Dashboard

### What I Need Built

**Page / component:** Main authenticated dashboard at `GET /dashboard`

**Requirements from DESIGN-SYSTEM.md section 6.3:**
- Purpose: Daily at-a-glance view — 7-day symptom summary, peak flow chart, medication adherence, low-stock alerts.
- `.page-header` with today's date (e.g., "Saturday, 8 March 2026") on the left, no action button.
- Symptom summary: row of three stat cards (Mild, Moderate, Severe) showing count for the last 7 days. Cards use `--severity-mild-bg` / `--severity-moderate-bg` / `--severity-severe-bg` backgrounds with corresponding text colours.
- Peak flow chart: Chart.js line chart inside a `.section-card`, last 7 days on x-axis, L/min on y-axis. Three horizontal zone bands (green ≥80% of personal best, yellow ≥50%, red <50%). Chart colours via `getComputedStyle` in `chart_controller.js`. Zone band colours: `rgba(22,163,74,0.08)` green, `rgba(217,119,6,0.08)` yellow, `rgba(220,38,38,0.08)` red.
- Adherence section: `.dash-adherence-list` showing preventer medications with on-track/missed status for today. If all on-track: show a single green "All medications taken today" row instead of the list.
- Low-stock section: shown only when one or more medications are within 14 days of running out. Each low-stock medication: name, days remaining, ".btn-refill" link.
- New user / no data: each section card shows its own `.empty-state` with a specific CTA.
- No personal best set: a `.flash--alert`-styled warning banner at the top of the page (not a flash, a persistent inline banner) with a link to `/profile` to set personal best.

**Additional context:**
- Files to modify: `app/views/dashboard/index.html.erb`, `app/assets/stylesheets/dashboard.css`.
- Existing Stimulus controller: `chart_controller.js` — already handles the Chart.js setup. Modify to pass zone band annotations using Chart.js annotation plugin, or use filled datasets to represent zones (three stacked area datasets behind the line). Use the simpler approach that avoids adding a new npm package.
- Symptom stat cards: use a horizontal flex row (gap `--space-md`). On mobile (375px) they should be a 1×3 column stack if they don't fit, otherwise a 3-column row. Each card: large number (2rem, `--font-heading`, bold) + label below ("mild this week"). Use existing `--severity-*` tokens for colour.
- The adherence section uses the existing `.dash-adherence-list` structure. The "All good" state: a single `.dash-adherence-item--on_track` with text "All medications taken today" and a ✓ icon.
- For the dashboard empty state (no data at all): show a single `.section-card` with a friendly welcome message and two buttons: "Log a symptom" and "Record peak flow". Skip the individual section empty states when there is truly no data yet.
- Realistic sample data for the chart: readings around 380–420 L/min over 7 days with one dip to 310 on day 3 (yellow zone). Personal best: 480 L/min.
- The peak flow chart section card title: "Peak Flow — Last 7 Days". Include a small zone legend below the chart (green dot + "Green zone", etc.) using flex row with `.adherence-legend` styles already defined.

---

## 5. Symptom Logs

### What I Need Built

**Page / component:** Three views — symptom log timeline (`GET /symptom_logs`), new log form (`GET /symptom_logs/new`), and edit form (`GET /symptom_logs/:id/edit`). The new and edit views share `_form.html.erb`.

**Requirements from DESIGN-SYSTEM.md section 6.4:**
- **Timeline (index):** `.page-header` with "+ Log symptom" CTA. Filter bar: symptom type chips (All, Wheezing, Coughing, Shortness of Breath, Chest Tightness), severity chips (All, Mild, Moderate, Severe), date range (from/to inputs). Filter chips use `.filter-chip` with an `--active` modifier. Filter bar is a Turbo Frame so filtering updates the list without a full page reload. Each timeline row: severity colour bar on the left (4px, `--severity-*`), symptom type name, severity badge, date + time, trigger tags (if any), notes excerpt (max 2 lines, clamped), edit + delete actions. Delete triggers confirm dialog.
- **New / Edit form:** `.section-card`. Fields in order: symptom type (select), severity (radio group — Mild / Moderate / Severe, each a visually styled card, not a bare radio), notes (Lexxy rich text), triggers (tag selector, `triggers_controller.js`), recorded at (datetime with "Right now" shortcut, `now_controller.js`). Submit: `.btn-primary` full-width on mobile. Cancel: `.btn-cancel`. Edit page adds a breadcrumb above `.page-header`.
- No logs empty state: icon of a notepad or symptom waveform (SVG, 48px, `--text-4`), headline "No symptoms logged yet", description "Tap the button above to log how you're feeling today.", CTA "Log a symptom".
- Loading filter results: skeleton rows (3 skeleton blocks, each the height of a timeline row).

**Additional context:**
- Files to modify: `app/views/symptom_logs/index.html.erb`, `new.html.erb`, `edit.html.erb`, `_form.html.erb`, `_timeline_row.html.erb`, `_filter_bar.html.erb`, `_pagination.html.erb`, `create.turbo_stream.erb`, `update.turbo_stream.erb`, `destroy.turbo_stream.erb`. CSS: `app/assets/stylesheets/symptom_timeline.css`.
- Severity radio cards: each option is a `<label>` wrapping a hidden `<input type="radio">` and a visible styled div. Unchecked: white card, `--border-mid` border. Checked: filled with the severity background colour and a coloured border. The three options sit side-by-side (flex row with equal widths). On mobile they can be a 3-column row at 375px — keep labels short ("Mild", "Moderate", "Severe").
- Trigger tag selector: a set of pre-defined trigger tags (Exercise, Cold air, Pollen, Dust, Smoke, Stress, Infection, Pet dander, Strong smells, Unknown). Each tag is a pill-shaped toggle chip. Selected state: `background: var(--brand); color: #fff`. Unselected: `background: var(--surface); border: 1px solid var(--border-mid); color: var(--text-3)`. The Stimulus `triggers_controller.js` manages a hidden field containing the JSON array of selected values.
- Timeline rows: on mobile, stack the date below the symptom type. On desktop, show them inline. Trigger tags in the row are truncated to a maximum of 3 shown + "+N more" indicator if there are more.
- Turbo Stream for create: prepend the new row to the timeline list and dispatch `toast:show` with `{ message: "Symptom logged.", variant: "success" }`.
- Turbo Stream for destroy: remove the row and dispatch `toast:show` with `{ message: "Symptom log deleted.", variant: "success" }`.
- Pagination: "Previous" / "Next" buttons with page numbers. Current page button: `background: var(--brand); color: #fff`. Use `.pagination-btn` class.

---

## 6. Peak Flow

### What I Need Built

**Page / component:** Three views — peak flow history (`GET /peak_flow_readings`), new reading form (`GET /peak_flow_readings/new`), and edit form (`GET /peak_flow_readings/:id/edit`). New and edit share `_form.html.erb`.

**Requirements from DESIGN-SYSTEM.md section 6.5:**
- **History (index):** `.page-header` with "+ Record reading" CTA. Filter bar: date range inputs, zone chips (All, Green, Yellow, Red). Readings displayed in a `.data-table` inside `.table-wrap`: columns — Date/Time, Reading (L/min), Zone badge, Actions (Edit + Delete). Zone badge uses the badge colour system from DESIGN-SYSTEM.md section 2.4. Delete triggers confirm dialog. Zone legend below the table (green/yellow/red dot + label). Pagination below the legend.
- No personal best banner: amber-tinted `.flash`-style inline banner (not dismissible) at the top of the page: "Zone classification is off — set your personal best on your Profile page." with a "Set personal best →" link. Shown only when personal best is not set.
- No readings empty state: SVG lung icon (48px, `--text-4`), "No readings yet", "Record your peak flow each morning to track trends over time.", CTA "Record a reading".
- **New / Edit form:** `.section-card`. Fields: value (number input, 1–900, large — use `font-size: 1.5rem` on the input to make it feel like a focused data-entry widget), zone preview (live feedback powered by `zone_preview_controller.js` — shows the zone badge updating in real time as the user types), recorded at (datetime + "Right now" shortcut). Edit page adds breadcrumb.
- Zone preview: when no personal best is set, show muted text "Set a personal best in your Profile to see your zone." instead of the preview.

**Additional context:**
- Files to modify: `app/views/peak_flow_readings/index.html.erb`, `new.html.erb`, `edit.html.erb`, `_form.html.erb`, `_reading_row.html.erb`, `_filter_bar.html.erb`, `_pagination.html.erb`, `create.turbo_stream.erb`, `update.turbo_stream.erb`, `destroy.turbo_stream.erb`. CSS: `app/assets/stylesheets/peak_flow.css`.
- The large number input for peak flow: wrap it in a `.pf-value-field` div that centres the input and its unit label ("L/min") below it. On mobile this should feel like a native numeric input — use `inputmode="numeric"` and `type="number"`.
- Zone preview widget: a pill badge below the value input that updates as the user types. Uses `zone_preview_controller.js` which reads the personal best from a `data-personal-best` attribute on the form element. Badge shows "Green zone", "Yellow zone", or "Red zone" with the appropriate background/text colours from the badge system.
- Turbo Stream for create: prepend the new row to the table body and dispatch `toast:show` with `{ message: "Reading recorded.", variant: "success" }`.
- Turbo Stream for destroy: remove the table row and dispatch `toast:show` with `{ message: "Reading deleted.", variant: "success" }`.
- The `.data-table` on mobile: hide the "Date/Time" column label and show date inline with the reading value in a stacked layout. Use a responsive table approach — on mobile (`max-width: 640px`), switch to card-style rows rather than a horizontal table.
- Readings in the table should be sorted newest first.

---

## 7. Medications

### What I Need Built

**Page / component:** Three views — medication list at `GET /settings/medications`, new medication at `GET /settings/medications/new`, edit medication at `GET /settings/medications/:id/edit`. New and edit share `_form.html.erb`.

**Requirements from DESIGN-SYSTEM.md section 6.6:**
- **Medication list:** `.page-header` with "+ Add medication" CTA. Each medication is a `.med-row` (list row, not a full card) inside a `.section-card`. Row contents: medication name (bold), `.medication-badge` (type), remaining doses + days supply, a "Log dose" button (`.btn-sm`, teal outline), and an overflow `⋮` menu (edit, delete). Delete triggers confirm dialog. Low-stock rows: amber badge and `--severity-moderate` left border on the row. "Log dose" opens an inline `<details>` panel (no page navigation) with a puff count input, time input, and submit. Below the log form, the last 7 days of dose history is listed for that medication. Refill action in the overflow menu: opens an inline form to enter new dose count.
- No medications empty state: SVG inhaler icon (48px, `--text-4`), "No medications added", "Add your inhalers to track doses and get low-stock alerts.", CTA "Add medication".
- **New / Edit form:** `.section-card`. Fields in order: Name (text), Type (select: Reliever / Preventer / Combination / Other), Standard dose (number, puffs), Starting dose count (number, total puffs in a new inhaler), Sick-day dose (number, puffs), Doses per day (number), Last refilled (date). Edit page includes a "Delete medication" link at the very bottom (`.btn-delete`, full-width, triggers confirm dialog).

**Additional context:**
- Files to modify: `app/views/settings/medications/index.html.erb`, `new.html.erb`, `edit.html.erb`, `_form.html.erb`, `_medication.html.erb`, `create.turbo_stream.erb`, `update.turbo_stream.erb`, `destroy.turbo_stream.erb`, `refill.turbo_stream.erb`. Also `app/views/settings/dose_logs/_form.html.erb`, `_dose_log.html.erb`, `create.turbo_stream.erb`, `destroy.turbo_stream.erb`. CSS: `app/assets/stylesheets/settings.css`.
- The overflow `⋮` menu is a `<details>` element styled as a dropdown. Existing classes: `.med-overflow`, `.med-overflow-toggle`, `.med-overflow-menu`, `.med-overflow-item`. The menu closes when a click occurs outside it — wire this to a lightweight Stimulus controller or use a `<dialog>` polyfill.
- Inline dose log panel: existing class `.med-log-panel` (absolute positioned below the row). On mobile it should be full-width (relative positioned, not absolute, on `max-width: 640px`).
- Dose history inside the panel shows the last 7 dose logs for the medication: each entry shows time ("8:00 AM today", "Yesterday 9:00 PM") and puffs taken. Delete each dose log via a small `×` button (`.btn-delete--small`) with a confirm dialog.
- Form help text: add a small `<p class="field-hint">` below the "Starting dose count" input explaining: "Enter the total number of puffs when the inhaler is full. A standard reliever inhaler usually has 200 puffs." Style: `font-size: 0.875rem; color: var(--text-3); margin-top: 0.25rem; margin-bottom: 0`.
- Turbo Stream for dose log create: update the dose history list and the remaining doses display on the row, dispatch `toast:show` with `{ message: "Dose logged.", variant: "success" }`.
- On the new/edit form, the "Type" select should be the first field after Name — it determines how the medication is used and sets the right mental model before the user fills in dose counts.

---

## 8. Adherence History

### What I Need Built

**Page / component:** Medication adherence calendar grid at `GET /adherence`

**Requirements from DESIGN-SYSTEM.md section 6.7:**
- Purpose: Calendar-grid view of preventer medication adherence.
- `.page-header` with title "Adherence History". Right side: toggle button group — "7 days" / "30 days" (`.btn-sm` + `.btn-sm--active` for the selected period). Toggling is a Turbo Frame navigation with `?period=7` or `?period=30`.
- One `.adherence-medication-section` per preventer medication. Section heading: medication name (bold, `--font-heading`) and schedule subtitle (e.g., "2 puffs, twice daily" in `--text-3`).
- `.adherence-grid`: `repeat(7, 36px)` columns for 7-day view; `repeat(7, 36px)` columns with multiple rows for 30-day view (5 rows × 7 columns = 35 cells + 1 extra = 36 shown). Each cell: a 36×36px square with a day abbreviation label above it. Cell states: on-track (`--severity-mild`, white tick), missed (`--severity-severe`, white ×), no schedule (`--border`, `--text-3`).
- Legend below the grid: three coloured squares + labels.
- No preventer medications empty state: `.empty-state` — "No preventer medications", "Add a preventer inhaler in Settings to track adherence.", CTA "Go to medications".
- Back link at the bottom: "← Back to dashboard".

**Additional context:**
- Files to modify: `app/views/adherence/index.html.erb`, `_history_grid.html.erb`. CSS: in `application.css` (adherence styles already exist: `.adherence-grid`, `.adherence-cell`, `.adherence-legend`).
- The 30-day grid: render 30 cells across 5 rows. Group by week (7 cells per row). Each row represents one week. Day labels above the grid should show the day abbreviations (Mon, Tue, Wed, Thu, Fri, Sat, Sun) as a header row above all the cell rows — not repeated per row.
- In the 30-day view, days that haven't happened yet (future dates) show as `.adherence-cell--no_schedule` regardless of schedule.
- The toggle buttons are inside a `.adherence-toggle` (flex row) in the `.page-header`. They use Turbo Frame so the grid updates without a full page reload.
- Tooltips on cells: on hover, show a `<span role="tooltip">` with the full date and status (e.g., "Wednesday 5 Mar — 2/2 doses taken"). Use CSS-only tooltip (`:hover + .tooltip` pattern) — no JavaScript needed.
- Turbo Frame wrapper: the entire grid area (excluding the page header and toggle) should be inside `<turbo-frame id="adherence-grid">` so the period toggle only refreshes the grid.

---

## 9. Profile and Account Deletion

### What I Need Built

**Page / component:** User profile page at `GET /profile` — four form sections plus the danger zone.

**Requirements from DESIGN-SYSTEM.md section 6.8:**
- Four `.section-card` sections stacked vertically:
  1. **Avatar:** Current avatar image (80px circle) or initials fallback. "Change photo" button (file input, styled as `.btn-secondary`). Remove avatar link (inline confirm "Are you sure? Remove" — no modal for this low-stakes action). Accepted: JPG, PNG, WebP. Max size: 5 MB. Preview updated immediately on file selection via Stimulus.
  2. **Personal details:** Full name (text input). Email address (text input, note below: "Changing your email will require re-verification."). Save button (`.btn-primary`).
  3. **Change password:** Current password, new password, confirm new password. Password fields all have show/hide toggles (`password_visibility_controller.js`). Save button.
  4. **Personal best peak flow:** Number input (100–900 L/min). Help text: "Your personal best is used to calculate your green, yellow, and red zones. Use the highest reading you've achieved when feeling well." Save button.
- If personal best is not set: amber inline banner at the top of the page (persistent, not dismissible) above the first section card: "Your zone classification is off. Set your personal best below." Clicking it smooth-scrolls to the personal best card.
- **Danger zone (fifth section card):** Red-tinted header ("Danger Zone", red left border `--severity-severe`). Warning text: "Permanently deletes your account and all health data. This cannot be undone." Delete button (`.btn-delete`, full width): opens a `<dialog>` that requires the user to type their email address to confirm before the delete button inside the dialog is enabled.

**Additional context:**
- Files to modify: `app/views/profiles/show.html.erb`, `_avatar_form.html.erb`, `_personal_details_form.html.erb`, `_password_form.html.erb`, `_personal_best_form.html.erb`. CSS: `app/assets/stylesheets/profile.css`. Add a new partial `_danger_zone.html.erb`.
- Avatar preview: `avatar_preview_controller.js` — new Stimulus controller. On `change` event on the file input, read the file with `FileReader` and update an `<img>` or the initials `<div>` with the preview URL. Show the image element, hide the initials element.
- All four save buttons submit independently (each section is its own `<form>`). Success feedback for each form is a toast (`toast:show`), not a full page reload. Use Turbo Stream for each form submission.
- The danger zone section card needs a new BEM modifier: `.section-card--danger`. Add to `profile.css`: red-tinted `border-color: var(--severity-severe)` and a subtle `background: var(--severity-severe-bg)` on just the header portion (`.section-card-header--danger`).
- Account deletion dialog: the confirm input is a text input. The "Delete my account" button inside the dialog starts disabled. Wire a Stimulus `confirm_email_controller.js` that compares the input value to the user's email (passed via a `data-email` attribute) and enables/disables the button reactively.
- The "Set personal best" section: when saved, dispatch a Turbo Stream that also updates the amber banner (remove it if a value was successfully set).

---

## 10. Settings Hub

### What I Need Built

**Page / component:** Settings hub / navigation page at `GET /settings`

**Requirements from DESIGN-SYSTEM.md section 6.8:**
- Purpose: Central navigation for all settings sub-sections. Currently shows Medications only. Designed to grow.
- `.page-header` with title "Settings".
- A grid of navigation cards — one card per sub-section. Each card: a `.section-card` styled as a clickable link (`.section-card--nav`), containing an SVG icon (24px, `--brand`), a bold title, a one-sentence description, and a right-pointing chevron (→). Card hover state: `border-color: var(--brand); box-shadow: var(--shadow-md)`.
- Current sub-sections to show: Medications (icon: pill/inhaler SVG, title: "Medications", description: "Manage your inhalers, log doses, and track stock."), Profile (icon: person SVG, title: "Profile", description: "Update your name, avatar, and personal best.").
- Layout: two-column grid on desktop (auto-fit, min 280px, gap `--space-md`), single column on mobile.

**Additional context:**
- Files to modify: `app/views/settings/show.html.erb`. CSS: `app/assets/stylesheets/settings.css` (add `.section-card--nav` modifier).
- The entire card is a link (`<a href="...">`). Wrap the `.section-card--nav` in an `<a>` tag. Reset link text-decoration on the card. The card body should not use `<h2>` for the title — use `<p class="settings-nav-title">` (bold, `--font-heading`, `--text`) to avoid a heading hierarchy issue (the page `<h1>` is "Settings").
- `.section-card--nav` CSS: add `cursor: pointer; transition: border-color 150ms ease-out, box-shadow 150ms ease-out`. Hover: `border-color: var(--brand); box-shadow: var(--shadow-md)`. Focus-visible on the wrapping `<a>`: standard focus ring.
- The chevron is a pure CSS arrow (`border-right + border-bottom` rotated 45°) or an inline SVG — either is fine. Colour: `--text-4`, moves to `--brand` on card hover.
- Do not redirect from `/settings` to `/settings/medications`. Render this hub page instead.

---

## 11. Health Events

### What I Need Built

**Page / component:** Three views — health events list at `GET /health_events`, new event form at `GET /health_events/new`, edit event form at `GET /health_events/:id/edit`. New and edit share `_form.html.erb`.

**Requirements from DESIGN-SYSTEM.md section 6.9:**
- **List (index):** `.page-header` with "+ Add event" CTA. Events displayed inside a `.section-card` as a timeline list — one row per event. Row: event type badge (colour-coded by type), date + time, notes excerpt (1 line, text-overflow ellipsis), edit + delete actions. Delete triggers confirm dialog.
- Event type badge colours:
  - Hospital visit: `background: var(--severity-severe-bg); color: var(--severity-severe)`.
  - GP appointment: `background: var(--brand-light); color: var(--brand)`.
  - Illness: `background: var(--severity-moderate-bg); color: var(--severity-moderate-text)`.
  - Medication change: `background: var(--teal-100); color: var(--teal-700)`.
  - Other: `background: var(--surface-alt); color: var(--text-3)`.
- Empty state: "No health events recorded.", "Add events like GP visits or illness episodes to see them on your peak flow chart.", CTA "Add an event".
- **New / Edit form:** `.section-card`. Fields in order: event type (select — Hospital visit, GP appointment, Illness, Medication change, Other), recorded at (datetime + "Right now" shortcut, `now_controller.js`), notes (Lexxy rich text, optional). Submit button, cancel link. Edit page: breadcrumb "Health Events > Edit", delete button at bottom (triggers confirm dialog).

**Additional context:**
- Files to create: `app/views/health_events/` directory with `index.html.erb`, `new.html.erb`, `edit.html.erb`, `_form.html.erb`, `_event_row.html.erb`, `create.turbo_stream.erb`, `update.turbo_stream.erb`, `destroy.turbo_stream.erb`. Create `app/assets/stylesheets/health_events.css`. Create `HealthEventsController` with full CRUD actions.
- The health event model needs to be created as part of Phase 15 — this prompt covers only the view/CSS layer. Assume the model exists with fields: `event_type` (enum), `recorded_at` (datetime), `notes` (rich text via Lexxy), `user_id`.
- Event type badge: use a shared `.event-badge` class with `--type` modifiers matching the colours above. Same size and shape as `.medication-badge`.
- The event timeline in the list view is sorted newest first. Group by month: show a month heading (`<h3>` style: `font-size: 1rem; font-weight: 600; color: var(--text-3)`) before each new month's events, e.g., "March 2026".
- Turbo Stream for create: prepend new row to the list, dispatch `toast:show` with `{ message: "Health event recorded.", variant: "success" }`.
- Turbo Stream for destroy: remove the row, dispatch `toast:show` with `{ message: "Health event deleted.", variant: "success" }`.
- Add "Health Events" to the bottom nav on mobile as the fifth tab (replacing Profile, which moves to the avatar menu on mobile). Actually — do not change the bottom nav without a separate decision. Flag this as a follow-up.

---

## 12. Notifications

### What I Need Built

**Page / component:** Notifications feed at `GET /notifications`

**Requirements from DESIGN-SYSTEM.md section 6.10:**
- `.page-header` with title "Notifications". Right side: "Mark all read" button (`.btn-secondary btn-sm`) — shown only if there are unread notifications.
- Notification list inside a `.section-card`. Each item:
  - Left: 20px SVG icon, coloured by notification type (low stock: `--severity-moderate-text`, missed dose: `--severity-severe`, peak flow reminder: `--brand`, system/general: `--text-3`).
  - Centre: body text (one sentence, bold for unread, normal weight for read) + relative timestamp below in `--text-3` (e.g., "2 hours ago").
  - Right: unread indicator — a 6px teal circle (`--brand`). Hidden when read.
  - Entire row is a link to the relevant record.
  - Unread row background: `--brand-light`. Read row background: `--surface`.
- Row separator: `border-bottom: 1px solid var(--border)`. Last row: no border.
- Mark individual notification as read on click (Turbo Stream — update the row background and remove the unread dot).
- "Mark all read" Turbo Stream: update all rows simultaneously.
- Unread count badge on the top nav bell icon (when present): 8px red circle overlaid on the icon. On mobile: same badge on the bottom nav.
- Empty state (all read / no notifications): `.empty-state` — checkmark SVG icon (48px, `--severity-mild`), "You're all caught up.", "No new notifications.", no CTA button.

**Additional context:**
- Files to create: `app/views/notifications/index.html.erb`, `_notification.html.erb`, `mark_read.turbo_stream.erb`, `mark_all_read.turbo_stream.erb`. Create `NotificationsController`. Create `app/assets/stylesheets/notifications.css`. Add a `Notification` model (or use a simple Rails concern — flag for later architectural decision).
- The notification SVG icons are inline SVGs in the partial — pick simple, recognisable icons (24px viewBox, `currentColor` stroke, no fill). Use Heroicons outline style for consistency.
- Relative timestamps ("2 hours ago", "Yesterday"): use a Rails helper that formats `recorded_at` relative to `Time.current`. For the current session, use a `data-timestamp` attribute and a lightweight Stimulus controller (`relative_time_controller.js`) that updates the display every 60 seconds.
- The unread badge on the nav: add `data-unread-count` to the nav bell button element, rendered server-side. The badge is a CSS pseudo-element (`:after`) when the count is > 0. Passing the count requires a small layout change to include it in the nav partial — the count is read from `Current.user.notifications.unread.count`.
- Flag for follow-up: where does "Notifications" live in the bottom nav? Currently 5 tabs are: Dashboard, Symptoms, Peak Flow, Medications, Profile. Adding Notifications requires either removing one or using a "More" overflow tab. Recommend: replace the Profile tab with a Notifications tab and move Profile into the avatar dropdown on mobile (it's already there on desktop).

---

## 13. Legal Pages and Cookie Banner

### What I Need Built

**Page / component:** Three legal pages (Terms of Service at `GET /terms`, Privacy Policy at `GET /privacy`, Cookie Policy at `GET /cookies`) and a cookie consent banner shown on first visit to any page.

**Requirements from DESIGN-SYSTEM.md section 6.11:**
- All three pages: single `.section-card` at max-width `680px` (narrower than standard 860px). Plain prose layout: `<h2>` section titles, `<p>` body, `<ul>` lists. No sidebar.
- Last updated date below the page title: `<p class="legal-date">Last updated: March 2026</p>` in `--text-3`, `0.875rem`.
- Cookie consent banner: fixed at the bottom of every page, above the bottom nav on mobile. One-line copy: "We use essential cookies only to keep you signed in." — "Got it" button (`.btn-primary btn-sm`) and "Learn more" link to `/cookies`. On dismiss: set a `cookies_accepted=1` session cookie via a lightweight Stimulus controller (`cookie_banner_controller.js`) and hide the banner with a CSS transition. Banner is never shown again once dismissed.

**Additional context:**
- Files to create: `app/views/pages/terms.html.erb`, `app/views/pages/privacy.html.erb`, `app/views/pages/cookies.html.erb`. Create `PagesController` with `terms`, `privacy`, `cookies` actions (no auth required). Create `app/assets/stylesheets/legal.css`. Add the cookie banner partial `app/views/layouts/_cookie_banner.html.erb` and render it in `application.html.erb` above `</body>`.
- Legal page content: write realistic, concise copy appropriate for a health tracking PWA. Do not use lorem ipsum. Terms should cover: account creation, acceptable use (personal health tracking only), data ownership (user owns their data), liability limitations. Privacy should cover: what data is collected (health logs, account info), how it's stored (SQLite on the user's server), no third-party sharing, deletion rights. Cookie policy: one essential cookie (session), no analytics, no advertising cookies.
- The `.section-card` on legal pages uses the existing class — no new modifier needed. Set `max-width: 680px` on the wrapping `<main>` element via an inline style or a page-specific CSS class `main--narrow`.
- Cookie banner CSS: `position: fixed; bottom: 0; left: 0; right: 0; z-index: 200`. On mobile: `bottom: 52px` (above the bottom nav). Background `--surface`, `border-top: 1px solid var(--border)`, `box-shadow: 0 -2px 8px rgba(0,0,0,0.06)`. Content: flex row, text left, buttons right. On mobile: stacked column.
- `cookie_banner_controller.js`: on "Got it" click, set `document.cookie = "cookies_accepted=1; max-age=31536000; path=/"`, then add a CSS class that transitions the banner to `opacity: 0` then `display: none`. The banner is conditionally rendered server-side: check for the `cookies_accepted` cookie in `ApplicationController` and set `@show_cookie_banner` accordingly.
- Add routes: `get '/terms', to: 'pages#terms'`, `get '/privacy', to: 'pages#privacy'`, `get '/cookies', to: 'pages#cookies'`.

---

## 14. Error Pages

### What I Need Built

**Page / component:** Three error pages — 404 Not Found, 500 Internal Server Error, and Maintenance.

**Requirements from DESIGN-SYSTEM.md section 6.12:**
- 404: "This page doesn't exist." + "The page you're looking for may have been moved or deleted." + link to Dashboard (or Home if unauthenticated).
- 500: "Something went wrong." + "An unexpected error occurred. Try refreshing, or come back in a moment." + link to Dashboard.
- Maintenance: "We'll be back shortly." + "Asthma Buddy is temporarily down for maintenance. Check back in a few minutes." No links (server may be fully down).
- All three: use the same layout shell if the layout is available. Fall back to inline-styled static HTML if not.
- These are static pages — no database calls, no Current.user access.

**Additional context:**
- Files to create or modify: `app/views/errors/not_found.html.erb`, `app/views/errors/internal_server_error.html.erb`, `public/maintenance.html` (fully static, no Rails layout). Create `ErrorsController` with `not_found` and `internal_server_error` actions. In `config/application.rb` (or `config/environments/production.rb`): `config.exceptions_app = self.routes` and add the error routes to `routes.rb`.
- Error page layout: use `layouts/application.html.erb` for 404 and 500. These pages render inside `<main>` like any other page. Centre the content vertically within the viewport using `min-height: calc(100vh - var(--header-height))` with `display: flex; align-items: center; justify-content: center` on an inner container.
- Visual: large teal error code number (404 / 500) in `--font-heading`, `font-size: clamp(4rem, 12vw, 8rem)`, `color: var(--brand-light)` (very muted, behind the text). Headline in `--text`. Description in `--text-3`. Then the action link as `.btn-primary`.
- The muted large number effect: position it as `position: absolute; z-index: 0` with the content on `z-index: 1` above it, both inside a `position: relative` wrapper.
- `public/maintenance.html`: fully self-contained HTML file with inline `<style>` block that reproduces the minimum tokens needed (teal brand colour, Plus Jakarta Sans from Google Fonts CDN, Inter body). Centre the message on the page with flexbox. No JavaScript. No links. Just the Asthma Buddy logo text and the maintenance message.
- The Kamal maintenance page is served by the proxy before Rails boots — it must be a completely standalone HTML file in `public/`.
- Add `config.exceptions_app = self.routes` to `application.rb` and the following to `routes.rb`:
  ```ruby
  match '/404', to: 'errors#not_found', via: :all
  match '/500', to: 'errors#internal_server_error', via: :all
  ```
