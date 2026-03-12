---
status: complete
priority: p2
issue_id: 312
tags: [code-review, css, ui-consistency]
---

# 312 — P2 — Legal pages use off-pattern `.page-header` structure — teal header band CSS does not fire

## Problem Statement

Legal pages (`cookie_policy.html.erb`, `privacy.html.erb`, `terms.html.erb`) render a `.page-header` div, but it is wrapped inside a `.main--narrow` container div rather than being a direct child of `<main>`. The CSS rule that applies the teal-tinted header band — `main:has(> .page-header)` (application.css line 478) — uses a direct-child combinator (`>`), so it only fires when `.page-header` is an immediate child of `<main>`. Legal pages never satisfy this condition.

As a result, the legal pages do not display the teal header band that every other page in the application shows, creating a visible visual inconsistency. Additionally, the legal page `.page-header` omits the established inner structure (`page-header-main > page-header-left`) used on all other pages, which means any future CSS targeting those inner elements will also fail to apply.

## Findings

- `app/views/pages/cookie_policy.html.erb` line 4–5: `<div class="main--narrow"><div class="page-header">` — `.page-header` is a child of `.main--narrow`, not a direct child of `<main>`
- `app/views/pages/privacy.html.erb`: same pattern
- `app/views/pages/terms.html.erb`: same pattern
- `app/assets/stylesheets/application.css` line 478: `main:has(> .page-header) { ... }` — the `>` combinator requires `.page-header` to be a direct child of `<main>`
- `app/assets/stylesheets/application.css` line 484: `@media` variant of the same rule — same direct-child constraint
- All other pages with page headers (dashboard, symptom log, peak flow, notifications, settings subpages) place `.page-header` as a direct child of `<main>` and display the teal band correctly
- Legal page `.page-header` also omits `.page-header-main` and `.page-header-left` inner wrappers present on all other pages

**Affected files:**
- `app/views/pages/cookie_policy.html.erb`
- `app/views/pages/privacy.html.erb`
- `app/views/pages/terms.html.erb`

## Proposed Solutions

### Option A — Restructure legal page headers to match the established pattern (recommended)

Move `.page-header` outside of `.main--narrow` so it is a direct child of `<main>`, matching the structure every other page uses. Add the `page-header-main > page-header-left` inner wrappers. Move `.main--narrow` to wrap only the body content below the header. This makes legal pages visually consistent with the rest of the app and ensures all existing and future CSS rules apply correctly.

Expected structure:

```html
<main>
  <div class="page-header">
    <div class="page-header-main">
      <div class="page-header-left">
        <!-- icon, h1, subtitle -->
      </div>
    </div>
  </div>
  <div class="main--narrow">
    <!-- legal body content -->
  </div>
</main>
```

### Option B — Update the CSS selector to use a descendant combinator

Change `main:has(> .page-header)` to `main:has(.page-header)` (remove the `>`). This makes the header band fire even when `.page-header` is a nested descendant. Quick to implement but changes the selector semantics for all pages — if any page intentionally nests a `.page-header` without wanting the band, this will cause regressions. Requires audit of all pages before applying.

### Option C — Add a wrapper class to legal pages and target it in CSS

Add a modifier class (e.g. `page-header--legal`) to the legal page headers and create a separate CSS rule to apply the teal band for that variant. This avoids restructuring the HTML and avoids changing the shared selector. Higher maintenance cost — two separate code paths for what should be one pattern.

## Acceptance Criteria

- [ ] Legal pages display the teal header band consistent with all other pages in the application
- [ ] Legal page `.page-header` is a direct child of `<main>` (satisfying `main:has(> .page-header)`)
- [ ] Legal page headers include `.page-header-main > .page-header-left` inner wrapper structure
- [ ] The `.main--narrow` content container is preserved and continues to constrain body text width
- [ ] No visual regression on non-legal pages
- [ ] Visual consistency verified across cookie policy, privacy, and terms pages

## Technical Details

| Field | Value |
|---|---|
| Affected views | `app/views/pages/cookie_policy.html.erb`, `privacy.html.erb`, `terms.html.erb` |
| CSS rule | `application.css` line 478: `main:has(> .page-header)` |
| Root cause | `.page-header` nested inside `.main--narrow` — does not satisfy direct-child combinator |
| Failure mode | Teal header band CSS selector never fires on legal pages |
| Visual impact | Legal pages look structurally inconsistent with the rest of the application |
| Severity | P2 — user-visible visual inconsistency on public-facing pages |
| Fix complexity | Low — restructure three view files to move `.page-header` outside `.main--narrow` |
