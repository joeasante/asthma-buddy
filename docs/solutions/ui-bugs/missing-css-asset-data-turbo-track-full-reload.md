---
title: "Missing CSS asset referenced with data-turbo-track causes Turbo full-page reloads"
problem_type: runtime-error
component: "layouts/application.html.erb, Turbo Drive, Propshaft"
tags: [turbo, assets, propshaft, data-turbo-track, css, full-page-reload, fingerprint]
symptoms:
  - Unexpected full-page reloads during Turbo navigation for authenticated users
  - SPA-like navigation experience degraded — pages flash white on every visit
  - No obvious 404 in logs; asset pipeline may silently skip the missing reference
  - Only affects pages that include the broken layout
root_cause: "stylesheet_link_tag 'lexxy' with data-turbo-track: reload referenced a file that didn't exist in the asset pipeline. Turbo fingerprints all data-turbo-track assets and triggers a full-page reload when fingerprints change between navigations. A missing file produces an unstable fingerprint, breaking Turbo navigation silently."
---

# Missing CSS Asset with `data-turbo-track: "reload"` Causes Turbo Full-Page Reloads

## Problem

`app/views/layouts/application.html.erb` contained:

```erb
<%= stylesheet_link_tag "lexxy", "data-turbo-track": "reload" %>
```

But `lexxy.css` did not exist in `app/assets/stylesheets/`. The Lexxy component styles were embedded directly in `application.css`.

### Why this breaks Turbo

Turbo Drive tracks assets tagged with `data-turbo-track="reload"` by comparing their fingerprints across page visits. If the fingerprint changes between the current page and a newly fetched page, Turbo triggers a full-page reload to ensure the browser gets fresh assets.

When an asset file is missing:
- Propshaft/Sprockets may render an incomplete or empty `<link>` tag
- The fingerprint Turbo computes differs from what the next page returns (or is absent)
- Turbo detects a "changed asset" and forces a full reload — on **every navigation**

The result: authenticated users experience a full browser navigation on every Turbo visit instead of the seamless SPA-like transition.

## Root Cause

```erb
<!-- BEFORE — stylesheet_link_tag "lexxy" points to a non-existent file -->
<% if authenticated? %>
  <%= stylesheet_link_tag "lexxy",            "data-turbo-track": "reload" %>
  <%= stylesheet_link_tag "profile",          "data-turbo-track": "reload" %>
  <%= stylesheet_link_tag "charts",           "data-turbo-track": "reload" %>
  <!-- ... other valid stylesheets ... -->
<% end %>
```

`lexxy.css` doesn't exist. The styles are in `application.css`. The tag is a leftover from a refactor where the file was merged upstream.

## Solution

Remove the broken tag. The content is already in `application.css`.

```erb
<!-- AFTER — lexxy tag removed -->
<% if authenticated? %>
  <%= stylesheet_link_tag "profile",          "data-turbo-track": "reload" %>
  <%= stylesheet_link_tag "charts",           "data-turbo-track": "reload" %>
  <!-- ... other valid stylesheets ... -->
<% end %>
```

**One-line fix** — no other changes needed. The styles already load via `application.css`.

## Prevention

### Rule of thumb
Before adding a `stylesheet_link_tag` (especially with `data-turbo-track`):
1. Verify the file physically exists at `app/assets/stylesheets/<name>.css`
2. Confirm it appears in the Propshaft asset manifest: `bin/rails assets:manifest` or check `public/assets/.manifest.json` after precompilation

### `data-turbo-track: "reload"` is particularly dangerous for missing files
Unlike a missing stylesheet without `data-turbo-track` (which just silently loads nothing), a missing turbo-tracked asset causes **active, ongoing navigation breakage**. Treat any `data-turbo-track` reference like a hard dependency — if the file is removed or renamed, the tag must be updated immediately.

### Code review signals
- A `stylesheet_link_tag` references a name that doesn't appear as a `.css` file in `app/assets/stylesheets/`
- A refactor moves CSS from a separate file into `application.css` but doesn't remove the `stylesheet_link_tag` from the layout
- `git log --diff-filter=D -- app/assets/stylesheets/` shows a deleted file, check that all corresponding layout references were cleaned up

### Detection test

Add a test that verifies all turbo-tracked stylesheet references resolve to real files:

```ruby
test "all turbo-tracked stylesheets exist in asset pipeline" do
  # Parse the layout and find every stylesheet_link_tag with data-turbo-track
  layout_path = Rails.root.join("app/views/layouts/application.html.erb")
  content     = File.read(layout_path)
  names = content.scan(/stylesheet_link_tag\s+["']([^"']+)["'].*data-turbo-track/).flatten

  names.each do |name|
    css_path = Rails.root.join("app/assets/stylesheets/#{name}.css")
    assert File.exist?(css_path), "Turbo-tracked stylesheet '#{name}.css' not found at #{css_path}"
  end
end
```

## Related

- Turbo Drive documentation: "Reloading When Assets Change" — `data-turbo-track` behaviour
- `app/views/layouts/application.html.erb` — all `stylesheet_link_tag` declarations
- Propshaft asset manifest: `public/assets/.manifest.json` (after `assets:precompile`)
- Related solution: `docs/solutions/ui-bugs/lexxy-editor-css-missing-from-layout.md` — a prior instance of missing CSS in the Lexxy integration
