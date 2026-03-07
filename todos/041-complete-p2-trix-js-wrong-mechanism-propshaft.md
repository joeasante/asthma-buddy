---
status: complete
priority: p2
issue_id: "041"
tags: [code-review, frontend, assets, propshaft, performance]
dependencies: []
---

# `javascript_include_tag "trix"` Uses Wrong Mechanism for Propshaft + May Conflict With Lexxy

## Problem Statement

`app/views/layouts/application.html.erb` includes `<%= javascript_include_tag "trix" %>`. This app uses Propshaft (not Sprockets) and Importmap. `javascript_include_tag` is a Sprockets-era helper that looks for compiled assets — it does not integrate with Importmap. Additionally, planning docs indicate the frontend editor was migrated to Lexxy (Lexical-based), making `trix` JS possibly redundant on the frontend. At minimum, Trix should not be loaded on every page — it's only needed on the symptom log form.

## Findings

**Flagged by:** pattern-recognition-specialist (High), performance-oracle (P1 — clear win), kieran-rails-reviewer (P2), code-simplicity-reviewer

**Location:** `app/views/layouts/application.html.erb`, line 16

```erb
<%= javascript_include_tag "trix" %>
```

**Issues:**

1. **Wrong mechanism for Propshaft + Importmap.** Under Propshaft, JS is loaded via importmap pins in `config/importmap.rb`. `javascript_include_tag "trix"` works in Sprockets (asset pipeline compilation). In Propshaft, it resolves to a direct path — `trix` gem ships its own JS, but it may not be correctly located without a pin.

2. **Loaded globally.** Even if it works, Trix (~200KB) is loaded on every page: home, sign-in, sign-up, password reset, email verification. It's only needed on the symptom log form.

3. **May conflict with Lexxy.** Planning docs (`03-03-SUMMARY.md`) state the frontend editor was replaced by Lexxy (a Lexical editor). `lexxy` is pinned in `importmap.rb`. If Lexxy handles the rich text editor UI, Trix JS may not be needed at all on the frontend. ActionText's `has_rich_text` backend works without Trix JS — it only stores/retrieves rich text; the editor widget is a frontend concern.

**Clarification needed:** Does the app use Trix's editor widget (via `javascript_include_tag "trix"` or `action_text:install`'s importmap pin), or does Lexxy replace it entirely? The `form.rich_text_area :notes` helper in ERB renders ActionText's Trix editor by default unless overridden.

## Proposed Solutions

### Solution A: Move to `content_for :head` scoped to symptom log views (Recommended if Trix is needed)
Remove from layout, add to symptom log views that use `rich_text_area`:

```erb
<%# app/views/symptom_logs/index.html.erb %>
<% content_for :head do %>
  <%= javascript_include_tag "trix" %>
<% end %>
```

The layout already has `<%= yield :head %>`, so this works without layout changes.
- **Effort:** Small
- **Risk:** Low (verify Trix loads correctly on the form page)

### Solution B: Pin Trix via importmap (if Trix is the intended editor)
In `config/importmap.rb`:
```ruby
pin "trix"
pin "@rails/actiontext", to: "actiontext.js"
```
And import in `app/javascript/application.js`:
```js
import "trix"
import "@rails/actiontext"
```
This is what `rails action_text:install` does. More correct for importmap projects.
- **Effort:** Small
- **Risk:** Medium (need to verify Lexxy/Trix interaction)

### Solution C: Remove if Lexxy replaces Trix entirely
If Lexxy fully replaces the Trix widget and ActionText only stores the data, remove `javascript_include_tag "trix"` entirely.
- **Effort:** Tiny
- **Risk:** Low if confirmed Lexxy handles editing

## Recommended Action

First confirm whether Lexxy or Trix is the active frontend editor for `rich_text_area`. If Trix: Solution A (or B). If Lexxy: Solution C.

## Technical Details

- **File:** `app/views/layouts/application.html.erb`, line 16
- **Layout yield:** `<%= yield :head %>` exists at line 9 for content_for injection

## Acceptance Criteria

- [ ] Confirm which editor is active (Trix or Lexxy) by testing the symptom log form
- [ ] Trix/Lexxy JS loads only on pages that contain `rich_text_area`
- [ ] No JS errors on pages that don't need the editor
- [ ] The symptom log `notes` field functions correctly for creating/editing entries

## Work Log

- 2026-03-07: Created from second-pass code review. Flagged by pattern-recognition-specialist (High), performance-oracle (P1 clear win).
