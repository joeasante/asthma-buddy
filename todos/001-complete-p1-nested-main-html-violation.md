---
status: pending
priority: p1
issue_id: "001"
tags: [code-review, accessibility, html, architecture]
dependencies: []
---

# Nested `<main>` HTML Violation

## Problem Statement

`app/views/home/index.html.erb` wraps its content in `<main class="home">`, but the application layout (`app/views/layouts/application.html.erb`) already provides `<main role="main" id="main-content">` around `<%= yield %>`. The rendered HTML contains nested `<main>` elements, which is invalid per the HTML5 / WHATWG living standard. Screen readers and assistive technology use the `<main>` landmark to navigate to page content — nesting breaks that contract and will compound across every new view added in Phase 2+.

Every future developer will copy `home/index.html.erb` as a template and introduce the same violation.

## Findings

**Flagged by:** kieran-rails-reviewer, architecture-strategist, pattern-recognition-specialist, code-simplicity-reviewer (all 4 agents — unanimous)

**Location:**
- `app/views/home/index.html.erb` line 3: `<main class="home">`
- `app/views/layouts/application.html.erb` line 33: `<main role="main" id="main-content">`

**Rendered output:**
```html
<main role="main" id="main-content">
  <main class="home">       <!-- INVALID: nested <main> -->
    <h1>Asthma Buddy</h1>
  </main>
</main>
```

WCAG 2.1 SC 1.3.1 and 4.1.1 require valid, non-duplicated landmark roles.

## Proposed Solutions

### Option A — Replace with `<div>` (Recommended)
Replace `<main class="home">` with `<div class="home">` in `home/index.html.erb`. Use `<div>` with a page-scoped CSS class for all future views. Document this as the project convention.

**Pros:** Minimal change; no semantic ambiguity; easy to enforce as a rule.
**Cons:** None.
**Effort:** Small
**Risk:** None

### Option B — Remove wrapper entirely
Remove the `<main>` wrapper entirely. Content is already inside the layout's `<main>`.

**Pros:** Fewer elements in DOM.
**Cons:** Removes the page-specific CSS scoping class.
**Effort:** Small
**Risk:** None (no styles exist yet anyway)

### Option C — `content_for :body_class` pattern
Yield a per-page CSS class to the layout's `<main>` via `content_for :body_class` so the layout renders `<main class="<%= yield :body_class %>">`.

**Pros:** Centralises the `<main>` and allows page-specific scoping.
**Cons:** More indirection; complicates the layout slightly.
**Effort:** Small–Medium
**Risk:** Low

## Recommended Action

Option A — replace `<main class="home">` with `<div class="home">`.

## Technical Details

**Affected files:**
- `app/views/home/index.html.erb`
- `test/controllers/home_controller_test.rb` — `assert_select "main[role=main]"` will still pass but the test for a single `<main>` (recommended addition) will verify the fix

**Acceptance Criteria:**
- [ ] `app/views/home/index.html.erb` contains no `<main>` element
- [ ] Rendered HTML has exactly one `<main>` element
- [ ] `bin/rails test` passes
- [ ] HTML validator passes (no nested `<main>`)
- [ ] A structural contract test `assert_select "main", count: 1` is added

## Work Log

- 2026-03-06: Identified by all 4 review agents in Foundation Phase code review.

## Resources

- HTML living standard: https://html.spec.whatwg.org/multipage/grouping-content.html#the-main-element
- WCAG 2.1 SC 4.1.1
