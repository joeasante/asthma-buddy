---
status: complete
priority: p3
issue_id: 369
tags: [code-review, frontend, duplication]
dependencies: []
---

## Problem Statement

Inline SVG icons are duplicated across multiple views. The same print icon SVG appears 3 times in the appointment summary view, and the same document icon appears in both the dashboard and health report. These should be extracted into reusable partials.

## Findings

Copy-pasted SVG markup inflates view file size, makes icon updates error-prone (must change every instance), and clutters template logic. Extracting them into partials or a helper method centralizes maintenance.

## Proposed Solutions

- Create SVG partials under `app/views/shared/icons/` (e.g., `_print.html.erb`, `_document.html.erb`).
- Replace all inline SVG instances with `render "shared/icons/print"` calls.
- Alternatively, create an `icon_svg` helper method that renders the appropriate SVG by name.

## Technical Details

**Affected files:** app/views/appointment_summaries/show.html.erb, app/views/dashboard/index.html.erb

## Acceptance Criteria

- [ ] Duplicated SVG icons extracted into reusable partials or helper
- [ ] All views reference the shared partial instead of inline SVG
- [ ] Visual appearance of icons is unchanged
- [ ] No missing icons in any view that previously had inline SVGs
