---
status: complete
priority: p3
issue_id: "216"
tags: [code-review, accessibility, html, reliever-usage]
dependencies: []
---

# `aria-current` Is Semantically Incorrect for the 8w/12w Period Toggle

## Problem Statement

The period toggle links use `aria-current="true"` for the active selection:

```erb
aria: { current: @weeks == 8 ? "true" : nil }
```

`aria-current` conveys the "current" item in sequential navigation (current page, current step, current date). For a toggle between two options that updates chart data, `aria-selected` within a `role="tablist"` / `role="tab"` structure is the semantically correct choice.

## Findings

**Flagged by:** kieran-rails-reviewer (P3)

**Location:** `app/views/reliever_usage/index.html.erb` lines 57–61

```erb
<%= link_to "8 weeks", ...,
      role: nil,
      aria: { current: @weeks == 8 ? "true" : nil } %>
<%= link_to "12 weeks", ...,
      aria: { current: @weeks == 12 ? "true" : nil } %>
```

The container has `role="group"` which does not convey selectable tabs. Screen readers will announce `aria-current="page"` semantics, not toggle selection semantics.

## Proposed Solutions

### Option A — Use `role="tablist"` / `role="tab"` / `aria-selected` (Recommended)
**Effort:** Small | **Risk:** Very low

```erb
<div class="reliever-toggle" role="tablist" aria-label="Select date range">
  <%= link_to "8 weeks", ...,
        role: "tab",
        aria: { selected: @weeks == 8 } %>
  <%= link_to "12 weeks", ...,
        role: "tab",
        aria: { selected: @weeks == 12 } %>
</div>
```

**Pros:** Semantically correct. Screen readers announce "tab, selected" / "tab, not selected".
**Cons:** Minor — `role="tab"` on `<a>` elements is technically valid but `<button>` elements would be more natural for a non-navigating toggle. Since these links advance history (`turbo_action: "advance"`), `<a>` is appropriate.

### Option B — Accept `aria-current` (minor semantic imprecision)
**Effort:** None | **Risk:** None

The current state is accessible (screen readers will understand `aria-current`), just not optimal. Many apps use `aria-current` for toggles.

## Recommended Action

Option A in the next frontend maintenance pass. Not a blocking issue.

## Technical Details

- **Affected files:** `app/views/reliever_usage/index.html.erb`

## Acceptance Criteria

- [ ] Period toggle uses `role="tablist"` + `role="tab"` + `aria-selected`
- [ ] Active tab has `aria-selected="true"`, inactive has `aria-selected="false"`

## Work Log

- 2026-03-10: Identified by kieran-rails-reviewer.
