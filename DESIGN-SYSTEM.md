# Asthma Buddy — Design System

> **Status:** Living document. All new UI must reference tokens defined here. No raw hex values in components.

---

## 1. Visual Direction

Asthma Buddy is a daily health companion. The visual language is calm, clinical-adjacent, and trustworthy — not sterile. Teal is the brand colour because it reads as health-positive without the overused blue of generic medical software. Typography skews large and generous because users may be logging while symptomatic or fatigued.

---

### 1.1 Colour Palette

All tokens are defined as CSS custom properties in `application.css :root`.

#### Brand — Teal

| Token | Hex | Use |
|---|---|---|
| `--teal-50` | `#f0fdfa` | Brand tinted surface, hover backgrounds |
| `--teal-100` | `#ccfbf1` | Badge backgrounds, subtle tints |
| `--teal-200` | `#99f6e4` | Border accents, focus ring tints |
| `--teal-500` | `#14b8a6` | Focus rings |
| `--teal-600` / `--brand` | `#0d9488` | **Primary action colour** |
| `--teal-700` / `--brand-dark` | `#0f766e` | Hover state for primary |
| `--brand-light` | `#f0fdfa` | Button ghost backgrounds |
| `--brand-ring` | `rgba(13,148,136,0.2)` | Input focus shadow |

> Aliases `--blue-*` exist for backwards compatibility but should not be used in new CSS. Use `--teal-*` or semantic tokens.

#### Neutral — Gray

| Token | Hex | Use |
|---|---|---|
| `--gray-50` | `#f9fafb` | Alternate surface |
| `--gray-100` / `--surface-alt` | `#f3f4f6` | Hover backgrounds, disabled fills |
| `--gray-200` / `--border` | `#e5e7eb` | Default borders |
| `--gray-300` / `--border-mid` | `#d1d5db` | Stronger borders, input strokes |
| `--gray-400` / `--text-4` | `#9ca3af` | Placeholder text, disabled labels |
| `--gray-500` / `--text-3` | `#6b7280` | Muted body text, captions |
| `--gray-700` / `--text-2` | `#374151` | Secondary body text |
| `--gray-900` / `--text` | `#111827` | Primary body text |

#### Surfaces

| Token | Value | Use |
|---|---|---|
| `--bg` | `#f1f5f9` | Page background (slate-100) |
| `--surface` | `#ffffff` | Card and panel backgrounds |
| `--surface-alt` | `#f3f4f6` | Secondary surfaces, hover fills |

#### Semantic — Status

| Token | Hex | Use |
|---|---|---|
| `--severity-mild` | `#16a34a` | Green zone, success, on-track |
| `--severity-mild-bg` | `#dcfce7` | Green tinted background |
| `--severity-moderate` | `#d97706` | Yellow zone border (not text — fails AA on white) |
| `--severity-moderate-text` | `#92400e` | Amber text on white backgrounds |
| `--severity-moderate-bg` | `#fef3c7` | Amber tinted background |
| `--severity-severe` | `#dc2626` | Red zone, error, destructive |
| `--severity-severe-bg` | `#fee2e2` | Red tinted background |
| `--error-border` | `#fca5a5` | Error input borders |
| `--error-text-dark` | `#7f1d1d` | Error text in coloured panels |

**Semantic alias table for new components:**

| Purpose | Use token |
|---|---|
| Success / green | `--severity-mild` + `--severity-mild-bg` |
| Warning / amber | `--severity-moderate-text` + `--severity-moderate-bg` |
| Error / red | `--severity-severe` + `--severity-severe-bg` |
| Info / teal | `--brand` + `--brand-light` |

---

### 1.2 Typography

#### Font Pairing

| Role | Family | Weights | Import |
|---|---|---|---|
| **Display / Headings** | Plus Jakarta Sans | 700, 800 | Google Fonts |
| **Body / UI** | Inter | 400, 500, 600 | Google Fonts |

Both are set as CSS custom properties: `--font-heading` and `--font-body`. The body fallback stack is `ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif`.

> **Loading:** Import both fonts in the `<head>` with `display=swap`. Use `preconnect` to `fonts.googleapis.com` and `fonts.gstatic.com`.

#### Type Scale

| Element | Size | Weight | Line height | Letter spacing | Token / Class |
|---|---|---|---|---|---|
| Display / h1 | `2.25rem` (36px) | 800 | 1.25 | `-0.03em` | `h1` |
| Heading / h2 | `1.625rem` (26px) | 800 | 1.25 | `-0.025em` | `h2` |
| Subheading / h3 | `1.25rem` (20px) | 800 | 1.25 | `-0.015em` | `h3` |
| Section card title | `1.125rem` (18px) | 700 | 1.3 | — | `.section-card-title` |
| Body (base) | `1.125rem` (18px) | 400 | 1.6 | — | `body` |
| Body secondary | `1rem` (16px) | 400 | 1.625 | — | `p` |
| UI label | `1rem` (16px) | 500 | 1.4 | — | `label` |
| Small / caption | `0.9375rem` (15px) | 400–500 | 1.5 | — | — |
| XSmall / badge | `0.8rem` (12.8px) | 600 | 1.2 | `0.03em` | `.medication-badge` |
| Nav tab label | `0.6875rem` (11px) | 500 | 1 | `0.01em` | `.bottom-nav-tab` |

---

### 1.3 Spacing Scale

Base unit: **4px**. All spacing tokens are multiples.

| Token | Value | px |
|---|---|---|
| `--space-xs` | `0.25rem` | 4px |
| `--space-sm` | `0.5rem` | 8px |
| `--space-md` | `1rem` | 16px |
| `--space-lg` | `1.5rem` | 24px |
| `--space-xl` | `2rem` | 32px |
| `--space-2xl` | `3rem` | 48px |

Use bare rem values (`0.75rem`, `1.25rem`, etc.) for intermediate spacing not covered by tokens.

---

### 1.4 Border Radius

| Token | Value | Use |
|---|---|---|
| `--radius-sm` | `4px` | Badges, small tags, adherence cells |
| `--radius-md` | `6px` | Buttons (secondary, ghost), chips, dropdown items |
| `--radius-lg` | `8px` | Inputs, dropdowns, tooltips |
| `--radius-xl` | `14px` | Cards, auth card, modals |
| `--radius-pill` | `9999px` | Avatar, pill badges, toggle buttons |

---

### 1.5 Shadow Tokens

| Token | Value | Use |
|---|---|---|
| `--shadow-sm` | `0 1px 3px rgba(0,0,0,0.08), 0 1px 2px rgba(0,0,0,0.04)` | Cards, buttons |
| `--shadow-md` | `0 4px 8px rgba(0,0,0,0.08), 0 2px 4px rgba(0,0,0,0.04)` | Dropdowns, log panels |
| `--shadow-lg` | `0 8px 16px rgba(0,0,0,0.1), 0 4px 6px rgba(0,0,0,0.05)` | Modals, auth card, nav dropdown |

---

## 2. Component Standards

### 2.1 Buttons

All buttons must use `font-family: inherit` and `cursor: pointer`. Never remove outline on focus without replacing with a visible focus ring.

#### Variants

| Variant | Class | Background | Text | Border | Use |
|---|---|---|---|---|---|
| Primary | `.btn-primary` | `--brand` | `#fff` | none | Main CTA, form submit |
| Secondary | `.btn-secondary` | `--surface` | `--text-2` | `--border-mid` | Secondary actions |
| Ghost / Cancel | `.btn-cancel` | transparent | `--text-3` | none | Cancel, back, low-priority |
| Edit | `.btn-edit` | `--surface` | `--text-3` | `--border` | Inline edit in list rows |
| Destructive | `.btn-delete` | `--surface` | `--text-3` | `--border` | Inline delete; turns red on hover |
| Outline brand | `.btn-refill` / `.btn-now` | `--brand-light` | `--brand` | `--teal-200` | Contextual actions |
| Toggle active | `.btn-sm--active` | `--brand` | `#fff` | `--brand` | Active segment in toggle groups |

#### Size Variants

| Size | Padding | Font size | Min height (touch) |
|---|---|---|---|
| `sm` (add `.btn-sm`) | `0.375rem 0.875rem` | `0.9375rem` | 44px on touch devices |
| `md` (default) | `0.75rem 1.5rem` | `1rem` | 44px on touch devices |
| `lg` | `1rem 2rem` | `1.125rem` | 44px on touch devices |

> **Touch targets:** All interactive elements must meet WCAG 2.2 SC 2.5.8 (44×44px minimum) on `pointer: coarse` devices. This is enforced globally in `application.css`.

#### States

| State | Visual |
|---|---|
| Hover | Darker background or tinted surface (see per-variant) |
| Focus | `outline: 2px solid var(--teal-500); outline-offset: 2px` via `:focus-visible` |
| Active | `transform: scale(0.98)` (disabled if `prefers-reduced-motion`) |
| Disabled | `opacity: 0.65; cursor: not-allowed; transform: none` |

---

### 2.2 Form Inputs

#### Text / Email / Password / Number / Date / Datetime-local

```
border: 1px solid var(--border-mid)
border-radius: var(--radius-lg)
padding: 0.75rem 1rem
font-size: 1rem
background: var(--surface)
```

Focus: `border-color: var(--teal-500); box-shadow: 0 0 0 3px var(--brand-ring)`

Error: `border-color: var(--error-border)` + inline error message below field.

#### Textarea

Same as text inputs. No `resize: horizontal`. Allow `resize: vertical` only.

#### Select

Same visual spec as text inputs. Custom dropdown arrow via CSS or SVG background-image.

#### Checkbox & Radio

- Wrap in `<label>` that includes both the input and its text.
- Custom styled via CSS: checked state uses `--brand` fill.
- Touch target: 44px minimum via `min-height` on the label.

#### Toggle (boolean)

- Use `<input type="checkbox" role="switch">` with ARIA.
- Track: `--border-mid` unchecked, `--brand` checked.
- Knob: `#fff` circle, `box-shadow: var(--shadow-sm)`.

#### Field wrapper

```html
<div class="field">
  <label for="id">Label text</label>
  <input type="text" id="id" name="...">
  <!-- error message here if invalid -->
</div>
```

`.field` adds `margin-bottom: 2rem`.

---

### 2.3 Cards

#### Default (`.section-card`)

```
background: var(--surface)
border: 1px solid var(--border)
border-radius: var(--radius-xl)
box-shadow: var(--shadow-sm)
padding: 1.5rem 1.75rem
```

Use `.section-card-header` (flex row, border-bottom) and `.section-card-title` inside.

#### Interactive (hover state)

```
transition: box-shadow 150ms var(--ease), border-color 150ms var(--ease)
hover: box-shadow: var(--shadow-md); border-color: var(--border-mid)
```

#### Highlighted / warning

Add a coloured left border to signal status:

```css
/* Choose the token that matches the severity of the signal */
border-left: 4px solid var(--severity-mild);     /* success / on-track */
border-left: 4px solid var(--severity-moderate); /* warning / low stock */
border-left: 4px solid var(--severity-severe);   /* error / missed */
border-left: 4px solid var(--brand);             /* informational / selected */
```

Examples: `.medication-card--low-stock` uses `--severity-moderate`; `.dash-adherence-item--on_track` uses `--severity-mild`.

#### Auth card (`.auth-card`)

Centred, max-width 400px, `box-shadow: var(--shadow-lg)`. Used only on unauthenticated pages.

---

### 2.4 Badges and Status Indicators

#### Medication type badges (`.medication-badge`)

```
padding: 0.25rem 0.625rem
border-radius: var(--radius-pill)
font-size: 0.8rem; font-weight: 600
text-transform: uppercase; letter-spacing: 0.03em
```

| Modifier | Background | Text |
|---|---|---|
| `--reliever` | `--teal-100` | `--teal-700` |
| `--preventer` | `--severity-mild-bg` | `--severity-mild` |
| `--combination` | `--severity-moderate-bg` | `--severity-moderate-text` |
| `--other` | `--surface-alt` | `--text-3` |

#### Zone badges (peak flow)

| Zone | Background | Text | Border-left colour |
|---|---|---|---|
| Green | `--severity-mild-bg` | `--severity-mild` | `--severity-mild` |
| Yellow | `--severity-moderate-bg` | `--severity-moderate-text` | `--severity-moderate` |
| Red | `--severity-severe-bg` | `--severity-severe` | `--severity-severe` |

#### Severity badges (symptoms)

Same colour scheme as zones (mild = green, moderate = amber, severe = red).

#### Low-stock badge (`.low-stock-badge`)

```
background: --severity-moderate-bg
color: --severity-moderate-text
border-radius: --radius-pill
```

#### Adherence cells (`.adherence-cell`)

36×36px squares, `border-radius: 4px`.

| State | Background | Text |
|---|---|---|
| On track | `--severity-mild` | `#fff` |
| Missed | `--severity-severe` | `#fff` |
| No schedule | `--border` | `--text-3` |

---

### 2.5 Alerts and Inline Error Messages

#### Flash messages (`.flash`)

```css
padding: 0.875rem 1rem;
border-radius: var(--radius-lg);
border: 1px solid transparent; /* overridden per variant below */
```

| Variant | Background | Text | Border |
|---|---|---|---|
| `.flash--notice` | `--severity-mild-bg` | `#14532d` | `#86efac` |
| `.flash--alert` | `--severity-severe-bg` | `#7f1d1d` | `--error-border` |

Flash messages live in `#flash-messages` at the top of `<main>`. They are rendered server-side and replaced via Turbo Stream on form submission.

#### Inline field errors

```html
<p class="field-error">Error message text</p>
```

```css
.field-error {
  color: var(--severity-severe);
  font-size: 0.9rem;
  margin-top: 0.375rem;
  margin-bottom: 0;
}
```

Place the `.field-error` immediately after the `<input>` inside `.field`. Never use the browser's native validation popups — validate server-side and render errors in the DOM.

---

### 2.6 Data Tables

#### Structure

```html
<div class="table-wrap">
  <table class="data-table">
    <thead><tr>…</tr></thead>
    <tbody>…</tbody>
  </table>
</div>
```

`.table-wrap` provides `overflow-x: auto` for mobile scrolling.

#### Styling spec

```
border-collapse: collapse
width: 100%
font-size: 0.9375rem
```

| Element | Style |
|---|---|
| `th` | `font-weight: 600; color: var(--text-3); text-align: left; padding: 0.75rem 1rem; border-bottom: 2px solid var(--border-mid)` |
| `td` | `padding: 0.75rem 1rem; border-bottom: 1px solid var(--border); color: var(--text-2)` |
| Row hover | `background: var(--gray-50)` |
| Selected row | `background: var(--brand-light)` |

#### Sorting

- Sortable `th` gets a sort icon (up/down/neutral arrow SVG).
- Active sort column: `color: var(--text); font-weight: 700`.
- Click triggers a Turbo Frame navigation with `?sort=col&dir=asc|desc`.

#### Pagination

Use `.pagination-btn` (existing) for prev/next/page number buttons. Active page: `background: var(--brand); color: #fff`.

---

### 2.7 Modals and Confirmation Dialogs

Asthma Buddy uses the native `<dialog>` element driven by the `confirm_controller.js` Stimulus controller. CSS is in `confirm_dialog.css`.

#### Spec

```
dialog {
  border-radius: var(--radius-xl);
  box-shadow: var(--shadow-lg);
  max-width: 400px;
  padding: 2rem;
  border: 1px solid var(--border);
}
dialog::backdrop { background: rgba(0,0,0,0.4) }
```

#### Anatomy

1. Title (h2, `font-size: 1.25rem`)
2. Body text explaining the consequence
3. Two buttons: Destructive confirm (`.btn-delete` styled) + Cancel (`.btn-cancel`)

#### Rule

Every destructive action (delete, account deletion) **must** route through this dialog. Never fire a `DELETE` request from a direct button click without a confirmation step.

---

### 2.8 Toast Notifications

Toasts are used for success confirmations after Turbo Stream mutations where the page content has already updated and a flash message in the main content area would feel redundant.

**Spec:**

| Property | Value |
|---|---|
| Position | Bottom-right, 24px from edge. On mobile: bottom-centre, above bottom nav |
| Width | Max 360px |
| Duration | Auto-dismiss after **4 seconds** |
| Dismiss | Click anywhere on toast to dismiss immediately |
| Animation | Slide up + fade in on appear; fade out on dismiss |
| Stack | Max 3 visible at once; oldest dismissed first |

**Anatomy:**

```html
<div class="toast toast--success" role="status" aria-live="polite">
  <span class="toast-icon">✓</span>
  <span class="toast-message">Symptom log saved.</span>
</div>
```

**Variants:**

| Variant | Icon | Background | Text |
|---|---|---|---|
| Success | ✓ | `--severity-mild-bg` | `#14532d` |
| Error | ✗ | `--severity-severe-bg` | `#7f1d1d` |
| Info | ℹ | `--brand-light` | `--brand-dark` |

> **Implementation:** A Stimulus `toast_controller.js` attached to a `<div id="toast-container">` in the layout listens for a `toast:show` CustomEvent dispatched from Turbo Stream responses. The event `detail` carries `{ message, variant }`. The controller appends a toast element, starts a 4-second auto-dismiss timer, and removes the element on click or timeout.

---

### 2.9 Navigation

#### Top nav (`header`)

```
height: var(--header-height)  /* 4rem / 64px */
background: var(--surface)
border-bottom: 1px solid var(--border)
position: sticky; top: 0; z-index: 100
```

Contents (left to right): brand logo/name → spacer → nav links (desktop only) → user avatar dropdown.

Desktop nav links use `.nav-link`. Active page: `.nav-link[aria-current="page"]` (teal background + teal text).

#### User avatar dropdown (`.nav-dropdown`)

- Triggered by `.nav-avatar-btn` (pill button with avatar + name + chevron).
- Positioned `top: calc(100% + 0.5rem); right: 0`.
- Contains: Profile link, Sign out (separator + red hover).
- On mobile (<480px): hide user name and chevron — show avatar only.

#### Bottom nav (`.bottom-nav`) — mobile only

Displayed on `max-width: 768px`. Fixed to bottom, safe-area aware.

```
5 tabs: Dashboard | Symptoms | Peak Flow | Medications | Profile
```

Each tab: `flex: 1; min-height: 52px; flex-direction: column; align-items: center`.

Active indicator: 2px teal bar at top of active tab.

#### Mobile nav — no sidebar

This app uses a **mobile-first bottom tab nav** instead of a sidebar. There is no sidebar. On desktop the top nav contains the primary links.

#### Breadcrumbs

Used on sub-pages (e.g., Edit Symptom Log). Structure:

```html
<nav aria-label="Breadcrumb" class="breadcrumb">
  <ol>
    <li><a href="/symptom_logs">Symptom Logs</a></li>
    <li aria-current="page">Edit</li>
  </ol>
</nav>
```

```css
.breadcrumb ol { display: flex; gap: 0.5rem; list-style: none; padding: 0; font-size: 0.9rem; color: var(--text-3); }
.breadcrumb li + li::before { content: "/"; margin-right: 0.5rem; color: var(--text-4); }
.breadcrumb a { color: var(--text-3); }
.breadcrumb a:hover { color: var(--brand); }
```

---

### 2.10 Empty States

```html
<div class="empty-state">
  <p class="empty-state-icon">🫁</p>
  <p class="empty-state-heading">No symptom logs yet</p>
  <p class="empty-state-body">Start tracking how you feel each day.</p>
  <a href="/symptom_logs/new" class="btn-primary">Log a symptom</a>
</div>
```

```css
.empty-state {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius-xl);
  box-shadow: var(--shadow-sm);
  padding: 3rem 1.5rem;
  text-align: center;
  color: var(--text-3);
}
.empty-state-icon { font-size: 2.5rem; margin-bottom: 0.75rem; }
.empty-state-heading { font-family: var(--font-heading); font-weight: 700; font-size: 1.125rem; color: var(--text); margin-bottom: 0.5rem; }
.empty-state-body { font-size: 0.9375rem; color: var(--text-3); margin-bottom: 1.5rem; }
```

---

### 2.11 Loading States — Skeleton Screens

Use skeleton screens (not spinners) whenever a section of page content is loading asynchronously. Spinners are only acceptable for button-level feedback (e.g., after clicking Log Dose).

#### Skeleton element

```html
<div class="skeleton" style="width: 100%; height: 1.25rem;"></div>
```

```css
.skeleton {
  background: linear-gradient(90deg, var(--gray-100) 25%, var(--gray-200) 50%, var(--gray-100) 75%);
  background-size: 200% 100%;
  animation: skeleton-shimmer 1.5s infinite;
  border-radius: var(--radius-md);
}
@keyframes skeleton-shimmer {
  0% { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}
@media (prefers-reduced-motion: reduce) {
  .skeleton { animation: none; background: var(--gray-100); }
}
```

#### When to use skeleton vs spinner

| Scenario | Use |
|---|---|
| Page section loading on initial render | Skeleton |
| Turbo Frame lazy-loading a card | Skeleton |
| Button submitting a form action | Inline spinner (16px, adjacent to button label) |
| Nothing visible to the user while navigating | Nothing (Turbo handles it) |

---

### 2.12 Avatars and User Indicators

#### Sizes

| Size | Dimensions | Use |
|---|---|---|
| xs | 24px | Inline in text |
| sm | 28px | Nav avatar button |
| md | 40px | Profile page header |
| lg | 80px | Profile edit page |

#### Fallback (initials)

When no avatar image is set, render a circle with the user's initials:

```css
.avatar-initials {
  background: var(--brand);
  color: #fff;
  font-weight: 700;
  display: flex; align-items: center; justify-content: center;
  border-radius: 50%;
}
```

Font size = `40%` of container size (e.g., 28px container → 11px font, rounded to `0.6875rem`).

---

## 3. Interaction Standards

### 3.1 State Definitions

| State | Rule |
|---|---|
| **Hover** | Apply within `150ms var(--ease)` transition. Darken background or apply tint. Never change layout. |
| **Focus** | `outline: 2px solid var(--teal-500); outline-offset: 2px` via `:focus-visible` only. Mouse clicks must not show the ring. |
| **Active** | `transform: scale(0.98)` for buttons. Suppress if `prefers-reduced-motion`. |
| **Disabled** | `opacity: 0.65; cursor: not-allowed`. Disabled inputs must have `disabled` attribute (not just visual). Never disable a submit button mid-form — use a loading spinner instead. |

### 3.2 Form Validation

- **When to show errors:** After first submit attempt. Do not validate on every keystroke. After the first failed submit, validate on blur for each field.
- **Error format:** Short, direct, plain English. "Can't be blank." not "This field is required." Use active voice.
- **Error placement:** `.field-error` paragraph immediately after the input, within `.field`.
- **Error summary:** On server-rendered validation failures, show a `.flash--alert` at the top of the form listing all errors. This ensures screen readers encounter errors early.
- **Success:** Redirect with a `.flash--notice` or (for Turbo Stream updates) a toast.

### 3.3 Loading Feedback

| Trigger | Feedback |
|---|---|
| Turbo navigation | None (Turbo's progress bar handles it) |
| Turbo Frame lazy load | Skeleton inside the frame |
| Form submission (inline Turbo Stream) | Disable submit button + add spinner adjacent to label |
| Full-page form submit | Standard browser loading state |

### 3.4 Success Feedback

- **Turbo Stream mutations** (save dose, log symptom): Toast notification, 4s auto-dismiss, bottom-right.
- **Full redirect actions** (create symptom log, edit profile): `.flash--notice` at top of destination page.
- **Destructive actions** (delete): Toast — "Symptom log deleted." Undo is out of scope for the current milestone; the toast has no secondary action.

### 3.5 Destructive Actions

All destructive actions (record deletion, account deletion) **must**:

1. Be triggered by a `.btn-delete` or equivalent button.
2. Open the native `<dialog>` confirm modal before firing the `DELETE` request.
3. Never process on first click.

Exception: "Remove avatar" — show an inline confirmation link ("Are you sure? Remove") rather than a modal, as it is low-stakes and reversible.

---

## 4. Layout Standards

### 4.1 Navigation Heights

| Element | Value |
|---|---|
| Top nav height | `--header-height`: `4rem` (64px) |
| Bottom nav height (mobile) | `52px` + `env(safe-area-inset-bottom)` |
| Sidebar width | **N/A — no sidebar in this app** |

### 4.2 Content Width

| Token | Value | Use |
|---|---|---|
| `--container-max` | `860px` | Max-width of all `<main>` content |
| Auth card | `400px` | Centred auth forms |

`<main>` is `max-width: var(--container-max); margin: 0 auto; padding: 2.5rem 1.5rem`.

### 4.3 Page Header Structure

Every authenticated page opens with a `.page-header`:

```html
<div class="page-header">
  <h1>Page Title</h1>
  <a href="..." class="btn-primary btn-sm">+ Add Item</a>
</div>
```

On pages with breadcrumbs, the breadcrumb sits above `.page-header`.

### 4.4 Responsive Breakpoints

| Name | Width | Notes |
|---|---|---|
| Mobile | `375px` | Target for bottom nav, single-column layout |
| Tablet | `768px` | Bottom nav cutoff; switch to top-nav-only |
| Desktop | `1280px` | Content constrained to `--container-max` |
| Wide | `1536px` | Same as desktop — content does not expand further |

#### Key breakpoint rules

| Breakpoint | Change |
|---|---|
| `≤640px` | Reduce nav padding, reduce main padding to `1.5rem 1rem` |
| `≤768px` | Show bottom nav; hide desktop nav links; add bottom padding to main |
| `≤480px` | Hide avatar name + chevron in nav |

### 4.5 Grid System

No grid framework. Use CSS Grid or Flexbox directly.

- **Single column:** Default for all content.
- **Two column (feature cards):** `grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 1rem` — used on landing page features.
- **Adherence grid:** `grid-template-columns: repeat(7, 36px); gap: 4px` — calendar grid.
- **Form inline groups:** Flexbox with `flex-wrap: wrap; gap: 1rem`.

---

## 5. Accessibility Baseline

### 5.1 Contrast Ratios

| Pair | Minimum ratio | Standard |
|---|---|---|
| Body text on background | 7:1 | WCAG AAA |
| UI text on surfaces | 4.5:1 | WCAG AA |
| Large text (18px+) on surfaces | 3:1 | WCAG AA |
| Status colours on white | 4.5:1 (text must use dark variant) | WCAG AA |

> **Note:** `--severity-moderate` (`#d97706`) fails AA on white — use `--severity-moderate-text` (`#92400e`) for all text on white backgrounds.

### 5.2 Focus Ring

```css
:focus-visible {
  outline: 2px solid var(--teal-500); /* #14b8a6 */
  outline-offset: 2px;
  border-radius: var(--radius-sm);
}
:focus:not(:focus-visible) { outline: none; }
```

Never suppress `:focus-visible` without providing an equivalent ring. Custom focus styles on inputs use `box-shadow: 0 0 0 3px var(--brand-ring)` in addition to the border change.

### 5.3 Labels

- Every `<input>`, `<select>`, `<textarea>` must have an associated `<label>` via `for`/`id` or `aria-labelledby`.
- No placeholder-only labelling. Placeholders may supplement but never replace labels.
- Required fields: add `required` attribute and visually mark with an asterisk in the label: `<label>Weight <span aria-hidden="true">*</span></label>`.

### 5.4 Icon-only Buttons

Any button that contains only an icon (SVG or emoji) must have either:

- `aria-label="Descriptive action"` on the button, or
- A visually-hidden `<span class="sr-only">Descriptive action</span>` child.

```css
.sr-only {
  position: absolute;
  width: 1px; height: 1px;
  padding: 0; margin: -1px;
  overflow: hidden;
  clip: rect(0,0,0,0);
  white-space: nowrap;
  border: 0;
}
```

### 5.5 ARIA Patterns

| Pattern | Implementation |
|---|---|
| Current nav item | `aria-current="page"` on active link |
| Dialog | `<dialog>` element (native ARIA semantics) |
| Toggle switch | `<input type="checkbox" role="switch">` |
| Live flash area | `role="status"` or `aria-live="polite"` on `#flash-messages` |
| Toast container | `aria-live="polite"` |
| Loading state | `aria-busy="true"` on the region being updated |

---

## 6. Page Inventory

### 6.1 Public (Unauthenticated)

#### Home / Landing
- **Route:** `GET /`
- **Purpose:** App introduction; drive sign-up or sign-in.
- **Key components:** `.home-hero`, `.home-features` (auto-fit grid), `.btn-primary` (Sign up), `.btn-secondary` (Sign in), top nav with Sign in / Get started.
- **Special states:** Authenticated users are redirected to dashboard.

#### Sign In
- **Route:** `GET /session/new`
- **Purpose:** Email + password authentication.
- **Key components:** `.auth-card`, text inputs, `.btn-primary` (Sign in), links to sign up and forgot password.
- **Special states:** Flash alert on bad credentials.

#### Sign Up / Registration
- **Route:** `GET /registrations/new`
- **Purpose:** Create account. Triggers email verification.
- **Key components:** `.auth-card`, name + email + password inputs, `.btn-primary` (Create account).
- **Special states:** Flash alert on validation errors (duplicate email, weak password).

#### Forgot Password
- **Route:** `GET /passwords/new`
- **Purpose:** Request a password reset link via email.
- **Key components:** `.auth-card`, email input, `.btn-primary`, back to sign-in link.
- **Special states:** Post-submit shows confirmation message ("Check your email") — always shown regardless of whether email exists (prevents enumeration).

#### Password Reset
- **Route:** `GET /passwords/:token/edit`
- **Purpose:** Set a new password via emailed link.
- **Key components:** `.auth-card`, new password + confirm inputs, `.btn-primary`.
- **Special states:** Expired token shows error; redirect to forgot-password.

#### Email Verification
- **Route:** `GET /email_verifications/new`
- **Purpose:** Prompt user to check email for verification link. Also handles the verify action.
- **Key components:** `.auth-card`, instructional text, resend link.
- **Special states:** Already verified users are redirected to dashboard.

---

### 6.2 Onboarding (Planned — Phase 17)

#### Onboarding Wizard
- **Route:** `GET /onboarding` (step-based, e.g., `/onboarding/step/1`)
- **Purpose:** Guide new users through: (1) set personal best, (2) add first medication, (3) log first symptom or peak flow.
- **Key components:** Progress indicator (step dots), `.section-card`, step-specific forms, skip option.
- **Special states:** Completion redirects to dashboard with a welcome flash.

---

### 6.3 Dashboard

#### Dashboard / Home
- **Route:** `GET /dashboard` (root for authenticated users)
- **Purpose:** Daily at-a-glance view: 7-day symptom summary, peak flow chart, medication adherence, low-stock alerts.
- **Key components:**
  - Stat summary cards (symptom counts by severity)
  - Peak flow trend chart (Chart.js, `chart_controller.js`, zone-coloured lines)
  - `.dash-adherence-list` (preventer medications adherence)
  - Low-stock medication section (`.medication-card--low-stock`)
  - `.page-header` with date
- **Special states:**
  - New user (no data): empty state inside each section card with a CTA to log data
  - No personal best set: warning banner linking to Profile to set personal best (zone classification disabled)
  - All medications on-track: adherence section shows green "All good" state

---

### 6.4 Symptom Logging

#### Symptom Log List / Timeline
- **Route:** `GET /symptom_logs`
- **Purpose:** Chronological timeline of all logged symptoms with filter and pagination.
- **Key components:** `.page-header`, `.filter-bar` (symptom type + severity chips, date range), timeline rows (`_timeline_row`), `.pagination-btn`, Turbo Frame for filter updates.
- **Special states:**
  - No logs: empty state with "Log your first symptom" CTA
  - Loading filter results: skeleton rows

#### New Symptom Log
- **Route:** `GET /symptom_logs/new`
- **Purpose:** Record a symptom event.
- **Key components:** `.section-card`, symptom type select, severity radio group, notes (Lexxy rich text), triggers tag selector (`triggers_controller.js`), datetime field with "Right now" shortcut (`now_controller.js`).
- **Special states:** Validation errors flash + inline field errors.

#### Edit Symptom Log
- **Route:** `GET /symptom_logs/:id/edit`
- **Purpose:** Correct an existing log entry.
- **Key components:** Same as new, pre-populated. Breadcrumb: Symptom Logs > Edit.
- **Special states:** Record not found → 404.

---

### 6.5 Peak Flow

#### Peak Flow History
- **Route:** `GET /peak_flow_readings`
- **Purpose:** Tabular history of readings with zone colour coding, filter, pagination.
- **Key components:** `.page-header`, `.filter-bar` (date range, zone chips), readings table with zone badge per row, zone legend, pagination.
- **Special states:**
  - No readings: empty state with CTA
  - No personal best: banner warning zone classification is unavailable

#### New Peak Flow Reading
- **Route:** `GET /peak_flow_readings/new`
- **Purpose:** Record today's peak flow measurement.
- **Key components:** `.section-card`, number input (1–900), zone preview (`zone_preview_controller.js`), datetime shortcut.
- **Special states:** No personal best → zone preview shows "Set a personal best in your profile to see zone classification."

#### Edit Peak Flow Reading
- **Route:** `GET /peak_flow_readings/:id/edit`
- **Purpose:** Correct a reading.
- **Key components:** Same as new form. Breadcrumb: Peak Flow > Edit.

---

### 6.6 Medications

#### Medication List (Settings)
- **Route:** `GET /settings/medications`
- **Purpose:** Manage the user's medication profiles. Log doses inline.
- **Key components:** `.page-header`, medication rows (`.med-row`) with overflow menu (`⋮`), inline dose log panel (`details`/`summary`), dose history list, refill form, low-stock badges.
- **Special states:**
  - No medications: `.medications-empty-state` with "Add medication" CTA
  - Low stock: amber border on row / badge

#### New Medication
- **Route:** `GET /settings/medications/new`
- **Purpose:** Create a new inhaler profile.
- **Key components:** `.section-card`, name text input, type select, dose count inputs, doses-per-day number, sick-day dose input, refill date.
- **Special states:** Validation errors.

#### Edit Medication
- **Route:** `GET /settings/medications/:id/edit`
- **Purpose:** Update an existing medication profile.
- **Key components:** Same as new form, pre-populated. Includes a delete option at the bottom (triggers confirm dialog).

---

### 6.7 Adherence

#### Adherence History
- **Route:** `GET /adherence`
- **Purpose:** Calendar-grid view of preventer medication adherence over 7 or 30 days.
- **Key components:** Toggle buttons (7 day / 30 day), per-medication `.adherence-grid`, legend, back link.
- **Special states:**
  - No preventer medications: empty state
  - All missed: grid filled red

---

### 6.8 Profile and Account Settings

#### Profile
- **Route:** `GET /profile`
- **Purpose:** Edit personal details, avatar, password, and personal best peak flow.
- **Key components:** `.section-card` × 4 (avatar, personal details, password, personal best), avatar upload with preview, form partials, `.flash` messages.
- **Special states:**
  - No avatar: initials fallback
  - Personal best not set: prompt banner on dashboard links here

#### Settings Hub
- **Route:** `GET /settings`
- **Purpose:** Entry point for account configuration. Currently redirects to Medications. As sub-sections grow (account deletion, notification preferences, data export), this becomes a nav card grid — one `.section-card` per sub-area with a title, one-line description, and a right-arrow link.
- **Key components:** `.page-header`, grid of `.section-card` nav items, each with a title and descriptive subtitle.
- **Special states:** Redirect to `/settings/medications` while only one sub-section exists.

#### Account Deletion
- **Route:** Inline "Danger Zone" section at the bottom of `GET /profile`
- **Purpose:** GDPR-compliant permanent account and data deletion.
- **Key components:** `.section-card` with a red-tinted header ("Danger Zone"), plain-English warning of what will be deleted, `.btn-delete` that opens the confirm dialog. The dialog body requires the user to type their email address to confirm. On submit: schedule background deletion, destroy the session, redirect to the home page with a notice.
- **Special states:** Password re-entry field invalid → inline field error; successful submission → flash notice on home page ("Your account has been scheduled for deletion.").

---

### 6.9 Health Events

#### Health Events List
- **Route:** `GET /health_events`
- **Purpose:** Chronological log of significant health events (hospital visit, GP appointment, illness, course of antibiotics/steroids) that appear as markers on the peak flow trend chart.
- **Key components:** `.page-header` with "+ Add event" CTA, `.section-card` wrapping a timeline list, event type badge per row, date + notes excerpt, edit/delete row actions.
- **Special states:** Empty state — "No health events recorded. Add events like GP visits or illness episodes to see them on your peak flow chart."

#### New Health Event
- **Route:** `GET /health_events/new`
- **Purpose:** Record a health event to annotate the peak flow chart.
- **Key components:** `.section-card`, event type select (Hospital visit, GP appointment, Illness, Medication change, Other), datetime field with "Right now" shortcut (`now_controller.js`), notes Lexxy field.
- **Special states:** Validation error if event type is blank.

#### Edit Health Event
- **Route:** `GET /health_events/:id/edit`
- **Purpose:** Correct an existing health event record.
- **Key components:** Same form as new, pre-populated. Breadcrumb: Health Events > Edit. Delete action at bottom triggers confirm dialog.

---

### 6.10 Notifications

#### Notifications Feed
- **Route:** `GET /notifications`
- **Purpose:** In-app feed of system-generated alerts: low-stock medication warnings, missed-dose reminders, and peak flow reminders.
- **Key components:** `.page-header` with "Mark all read" button (ghost, right-aligned), notification list inside a `.section-card`. Each item: unread indicator dot (6px teal circle), notification icon (SVG, 20px, coloured by type), body text, relative timestamp (e.g., "2 hours ago"), link to the relevant record.
- **Read/unread:** Unread items have `background: var(--brand-light)` and the teal dot. Read items have `background: var(--surface)` and no dot.
- **Notification types and icons:**

| Type | Icon | Colour |
|---|---|---|
| Low stock | Pill/inhaler | `--severity-moderate-text` |
| Missed dose | Clock | `--severity-severe` |
| Peak flow reminder | Wind/lungs | `--brand` |
| System / general | Bell | `--text-3` |

- **Special states:**
  - Empty (all read or none exist): centred `.empty-state` — "You're all caught up." with a checkmark icon.
  - Unread badge on nav: a small red dot (8px circle, `--severity-severe` background) overlaid on the bell icon in the top nav / bottom nav tab when unread count > 0.

---

### 6.11 Legal Pages

| Page | Route | Purpose |
|---|---|---|
| Terms of Service | `GET /terms` | Full terms of service |
| Privacy Policy | `GET /privacy` | How personal and health data is collected, stored, and deleted |
| Cookie Policy | `GET /cookies` | What cookies are used and why |

**Layout:** Each page uses a single centred `.section-card` inside `<main>` at max-width `680px` (narrower than the standard `860px` for comfortable long-form reading). Content is plain prose — `<h2>` for section titles, `<p>` for body, `<ul>` for lists. No sidebar.

**Cookie consent banner:** A fixed bottom bar (above the bottom nav on mobile) shown on first visit to any page. Contains a one-line summary ("We use essential cookies to keep you signed in."), a "Got it" dismiss button (`.btn-primary btn-sm`), and a "Learn more" link to `/cookies`. On dismiss, set a `cookies_accepted` cookie; the banner is never shown again. No tracking or analytics cookies are used — the banner is informational only.

---

### 6.12 Error Pages

| Page | Trigger | Key message |
|---|---|---|
| 404 Not Found | Unknown route or deleted record | "This page doesn't exist" + link to Dashboard |
| 500 Server Error | Unhandled exception | "Something went wrong. Try again shortly." + link to Dashboard |
| Maintenance | Kamal maintenance mode | "Asthma Buddy is temporarily down for maintenance." |

All error pages must be static (no database calls). Use the same layout shell (header, footer) if possible; fall back to a minimal inline style if the layout itself is broken.

---

## 7. Implementation Rules

### 7.1 File Naming

| Type | Convention | Example |
|---|---|---|
| CSS files | `snake_case.css` | `peak_flow.css`, `confirm_dialog.css` |
| CSS classes | `kebab-case` | `.section-card`, `.btn-primary` |
| CSS custom properties | `--kebab-case` | `--brand`, `--shadow-md` |
| ERB partials | `_snake_case.html.erb` | `_timeline_row.html.erb` |
| Stimulus controllers | `snake_case_controller.js` | `chart_controller.js` |
| Images | `kebab-case.ext` | `logo-mark.svg` |

### 7.2 Component Folder Structure

```
app/
  assets/
    stylesheets/
      application.css        ← tokens, reset, base, layout, shared components
      dashboard.css          ← dashboard-specific styles
      peak_flow.css          ← peak flow feature styles
      symptom_timeline.css   ← symptom log feature styles
      settings.css           ← settings + medication styles
      profile.css            ← profile page styles
      charts.css             ← chart container styles
      confirm_dialog.css     ← modal/dialog styles
      actiontext.css         ← Lexxy editor overrides
  javascript/
    controllers/
      chart_controller.js
      confirm_controller.js
      nav_dropdown_controller.js
      now_controller.js
      triggers_controller.js
      zone_preview_controller.js
      toast_controller.js
  views/
    layouts/
      application.html.erb
      _bottom_nav.html.erb
      _flash.html.erb
    symptom_logs/              ← example: one directory per resource
      index.html.erb
      new.html.erb
      edit.html.erb
      _form.html.erb
      _timeline_row.html.erb   ← row/card partial named after what it renders
      create.turbo_stream.erb  ← Turbo Stream partials named after the action
      update.turbo_stream.erb
      destroy.turbo_stream.erb
```

### 7.3 Props vs Hardcoded Content

- **Never hardcode colours as hex values in view templates or CSS files.** Always reference a CSS custom property: `color: var(--brand)`, not `color: #0d9488`.
- **Feature-specific classes** (e.g., `.peak-flow-zone-badge--green`) should reference semantic tokens internally, not raw values.
- **User-facing text** (labels, empty state copy, error messages) lives in the ERB view — not in CSS content properties or JS strings.
- **Repeated structural HTML** (form fields, table rows, cards) should be partials, not duplicated across templates.

### 7.4 Design Token Usage Rules

1. **No raw hex values** in any `.css` file except `application.css :root` where tokens are defined.
2. **No raw hex values** in `style=""` attributes in ERB templates. Use a CSS class.
3. When a one-off colour is genuinely needed, add a new token to `application.css :root` and document it here.
4. **Zone colours** must use the severity token system, not ad-hoc local variables.

### 7.5 Dark Mode

Dark mode is **not implemented** and is **not planned** for the current milestone. Do not add `@media (prefers-color-scheme: dark)` overrides. If dark mode is added in a future milestone, it will be implemented by redefining CSS custom properties under a `[data-theme="dark"]` selector, not by duplicating class definitions.

### 7.6 CSS Organisation within a File

Follow this order within each CSS file:

1. Section comment block
2. Container / layout rules
3. Child element rules (top to bottom, structural order)
4. Modifier classes (BEM-style: `--variant`)
5. State classes (`:hover`, `:focus`, `:disabled`)
6. Responsive overrides (`@media` blocks, smallest-to-largest)
7. Reduced-motion overrides (`@media (prefers-reduced-motion: reduce)`)

### 7.7 Adding New Pages

Before adding a new page:

1. Add it to Section 6 of this document with route, purpose, and components.
2. Identify which existing CSS file it belongs to, or create a new `feature.css` if none fits.
3. Reuse existing component classes wherever possible before writing new CSS.
4. Add any new tokens to `application.css :root` with a comment explaining their purpose.
