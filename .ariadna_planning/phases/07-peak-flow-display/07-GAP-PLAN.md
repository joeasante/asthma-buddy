---
phase: 07-peak-flow-display
plan: GAP
type: execute
wave: 1
depends_on: []
files_modified:
  - app/assets/stylesheets/application.css
autonomous: true
gap_closure: true

must_haves:
  truths:
    - "Navigation renders with readable brand, links, user email, and sign-out button"
    - "Flash notice and alert messages are visually distinct from body content"
    - "Page has consistent typography, spacing, and a contained layout on desktop"
    - "Header and footer are styled and visually separated from main content"
    - "Feature CSS custom properties (--severity-mild, --severity-moderate, --severity-severe) resolve correctly"
  artifacts:
    - path: "app/assets/stylesheets/application.css"
      provides: "Global base stylesheet with custom properties, reset, layout, nav, flash"
      contains: ":root"
  key_links:
    - from: "app/views/layouts/application.html.erb"
      to: "app/assets/stylesheets/application.css"
      via: "stylesheet_link_tag :app"
      pattern: "nav-brand|nav-link|nav-auth|nav-user-email|btn-sign-out|flash|flash--notice|flash--alert"
    - from: "app/assets/stylesheets/confirm_dialog.css"
      to: "app/assets/stylesheets/application.css"
      via: "var(--severity-severe)"
      pattern: "--severity-severe"
    - from: "app/assets/stylesheets/peak_flow.css"
      to: "app/assets/stylesheets/symptom_timeline.css"
      via: "var(--severity-mild/moderate/severe)"
      pattern: "--severity-mild|--severity-moderate|--severity-severe"
---

<objective>
Fill `application.css` with a complete global base stylesheet so the app is fully styled out of the box.

Purpose: Every page currently renders as unstyled HTML because `application.css` is empty. The layout references nav classes, flash classes, and structural elements that have no CSS definitions. Feature stylesheets consume custom properties (CSS variables) that are never declared globally. This single task resolves all of it.

Output: `app/assets/stylesheets/application.css` containing: CSS custom properties (colour palette, spacing, radii), a minimal box-sizing reset, base typography, page layout (body / header / nav / main / footer / container), navigation classes matching the layout HTML exactly, flash message classes, and base form/button/link styles.
</objective>

<execution_context>
@~/.claude/ariadna/workflows/execute-plan.md
@~/.claude/ariadna/templates/summary.md
</execution_context>

<context>
@/Users/josephasante/Code/asthma-buddy/.ariadna_planning/PROJECT.md
@/Users/josephasante/Code/asthma-buddy/.ariadna_planning/ROADMAP.md

<!-- Layout HTML — all nav and flash class names come from here -->
@/Users/josephasante/Code/asthma-buddy/app/views/layouts/application.html.erb

<!-- Feature CSS files — must not re-declare what they own; must provide what they consume -->
@/Users/josephasante/Code/asthma-buddy/app/assets/stylesheets/symptom_timeline.css
@/Users/josephasante/Code/asthma-buddy/app/assets/stylesheets/peak_flow.css
@/Users/josephasante/Code/asthma-buddy/app/assets/stylesheets/confirm_dialog.css
@/Users/josephasante/Code/asthma-buddy/app/assets/stylesheets/settings.css
</context>

<tasks>

<task type="auto">
  <name>Task 1: Write global base stylesheet into application.css</name>
  <files>app/assets/stylesheets/application.css</files>
  <action>
Replace the comment-only content of `app/assets/stylesheets/application.css` with a complete base stylesheet. Keep the existing header comment block at the top, then append the following sections in order:

**Section 1 — CSS custom properties on `:root`**

Declare all custom properties the app relies on. The severity variables are already declared in `symptom_timeline.css` but `confirm_dialog.css` consumes `--severity-severe` directly, so they MUST also live on `:root` in this file so they are available globally (symptom_timeline.css will re-declare them, which is harmless — last declaration wins within the same rule, and both are identical values):

```
:root {
  /* Severity / zone palette — consumed by symptom_timeline.css, peak_flow.css, confirm_dialog.css */
  --severity-mild:        #2d8a4e;
  --severity-moderate:    #c57a00;
  --severity-severe:      #c0392b;
  --severity-mild-bg:     #e8f5ee;
  --severity-moderate-bg: #fff8e6;
  --severity-severe-bg:   #fdecea;

  /* Brand colours */
  --color-brand:          #1a56db;
  --color-brand-hover:    #1648c3;

  /* Neutral greys */
  --color-text:           #1a1a1a;
  --color-text-muted:     #666;
  --color-text-subtle:    #888;
  --color-border:         #ddd;
  --color-border-light:   #eee;
  --color-surface:        #fff;
  --color-surface-alt:    #f5f5f5;
  --color-bg:             #f9f9f9;

  /* Spacing scale */
  --space-xs:   0.25rem;
  --space-sm:   0.5rem;
  --space-md:   1rem;
  --space-lg:   1.5rem;
  --space-xl:   2rem;

  /* Radii */
  --radius-sm:   4px;
  --radius-md:   6px;
  --radius-lg:   8px;
  --radius-pill: 9999px;

  /* Layout */
  --container-max: 860px;
  --header-height: 3rem;
}
```

**Section 2 — Box-sizing reset**

```
*,
*::before,
*::after {
  box-sizing: border-box;
}
```

**Section 3 — Base typography**

Use system-ui font stack. Body: `font-size: 1rem; line-height: 1.6; color: var(--color-text); background-color: var(--color-bg)`. Set `margin: 0` on body. Headings h1–h3: reasonable sizes (1.75rem, 1.375rem, 1.125rem), `font-weight: 600`, `line-height: 1.25`, `margin: 0 0 var(--space-sm)`. Paragraphs: `margin: 0 0 var(--space-md)`. Links: `color: var(--color-brand); text-decoration: none`. Links on hover: `text-decoration: underline`.

**Section 4 — Page layout**

`body`: `display: flex; flex-direction: column; min-height: 100vh`.

`header`: fixed height `var(--header-height)`, `background: var(--color-surface)`, `border-bottom: 1px solid var(--color-border)`, `position: sticky; top: 0; z-index: 100`.

`header nav`: `display: flex; align-items: center; justify-content: space-between; max-width: var(--container-max); margin: 0 auto; padding: 0 var(--space-md); height: 100%`.

`main`: `flex: 1; max-width: var(--container-max); margin: 0 auto; width: 100%; padding: var(--space-lg) var(--space-md)`.

`footer`: `border-top: 1px solid var(--color-border-light); padding: var(--space-md); text-align: center; font-size: 0.85rem; color: var(--color-text-muted)`.

**Section 5 — Navigation classes**

These class names must match `app/views/layouts/application.html.erb` exactly:

`.nav-brand`: `font-weight: 700; font-size: 1.05rem; color: var(--color-text); text-decoration: none`. Hover: `color: var(--color-brand)`.

`.nav-auth`: `display: flex; align-items: center; gap: var(--space-md)`.

`.nav-link`: `font-size: 0.9rem; color: var(--color-text-muted); text-decoration: none`. Hover: `color: var(--color-text)`.

`.nav-user-email`: `font-size: 0.85rem; color: var(--color-text-muted)`.

`.btn-sign-out`: Inline button that looks like a nav link. `background: none; border: none; padding: 0; font-size: 0.9rem; color: var(--color-text-muted); cursor: pointer; font-family: inherit`. Hover: `color: var(--color-text)`.

**Section 6 — Flash messages**

`#flash-messages`: `margin-bottom: var(--space-md)`.

`.flash`: `padding: 0.6rem var(--space-md); border-radius: var(--radius-sm); font-size: 0.9rem; margin-bottom: var(--space-sm)`.

`.flash--notice`: `background: var(--severity-mild-bg); color: #1a5c35; border: 1px solid #b6dfc5`.

`.flash--alert`: `background: var(--severity-severe-bg); color: #7b1d1d; border: 1px solid #f5b7b1`.

**Section 7 — Base form and button styles**

`input[type="text"], input[type="email"], input[type="password"], input[type="number"], input[type="date"], textarea, select`: `display: block; width: 100%; padding: 0.45rem 0.65rem; border: 1px solid var(--color-border); border-radius: var(--radius-sm); font-size: 1rem; font-family: inherit; background: var(--color-surface); color: var(--color-text)`. Focus: `outline: 2px solid var(--color-brand); outline-offset: 1px; border-color: var(--color-brand)`.

`label`: `display: block; font-size: 0.9rem; font-weight: 500; margin-bottom: var(--space-xs)`.

`.field`: `margin-bottom: var(--space-md)`.

`button, input[type="submit"]`: `cursor: pointer; font-family: inherit`.

Do NOT redeclare `.btn-primary` — it is already defined in `peak_flow.css`.
Do NOT redeclare `.btn-confirm-cancel` or `.btn-confirm-delete` — they are defined in `confirm_dialog.css`.
Do NOT redeclare any severity indicator, badge, timeline, or filter classes — they belong to their feature files.
  </action>
  <verify>
1. Run `bin/rails server` and open http://localhost:3000 in a browser (or check via curl that the stylesheet is served): `curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/assets/application.css` should return 200.
2. Run `bin/rubocop app/assets/stylesheets/application.css` — CSS files are not linted by RuboCop, so this step can be skipped. Instead confirm the file is non-empty: `wc -l app/assets/stylesheets/application.css` should show more than 10 lines.
3. Run the test suite to confirm nothing is broken: `bin/rails test`.
  </verify>
  <done>
`app/assets/stylesheets/application.css` contains `:root` with all custom properties, base reset, typography, page layout, nav classes (`.nav-brand`, `.nav-link`, `.nav-auth`, `.nav-user-email`, `.btn-sign-out`), flash classes (`.flash`, `.flash--notice`, `.flash--alert`), and form base styles. The test suite passes. No custom properties used by feature CSS are undefined.
  </done>
</task>

</tasks>

<verification>
- `app/assets/stylesheets/application.css` is non-empty and contains a `:root` block with custom properties.
- All class names referenced in `app/views/layouts/application.html.erb` (`nav-brand`, `nav-link`, `nav-auth`, `nav-user-email`, `btn-sign-out`, `flash`, `flash--notice`, `flash--alert`) have matching CSS rules in `application.css`.
- `--severity-mild`, `--severity-moderate`, `--severity-severe` and their `-bg` variants are declared on `:root` so `confirm_dialog.css` and `peak_flow.css` resolve them regardless of stylesheet load order.
- No class from `peak_flow.css`, `confirm_dialog.css`, `settings.css`, or `symptom_timeline.css` is redeclared in `application.css`.
- `bin/rails test` passes.
</verification>

<success_criteria>
The application renders with visible navigation, legible typography, a contained page layout, and styled flash messages. No browser console errors about missing CSS variables. Feature stylesheets continue to work without modification.
</success_criteria>

<output>
After completion, create `/Users/josephasante/Code/asthma-buddy/.ariadna_planning/phases/07-peak-flow-display/07-GAP-SUMMARY.md` following the standard summary template.
</output>
