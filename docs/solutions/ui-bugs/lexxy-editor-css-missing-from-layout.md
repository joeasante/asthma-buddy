---
title: Lexxy editor renders as unstyled symbols (CSS not linked in layout)
category: ui-bugs
tags: [lexxy, css, propshaft, asset-pipeline, stylesheet_link_tag, rich-text-editor, actiontext]
symptoms:
  - Lexxy editor toolbar displays as large raw symbols instead of styled icons
  - Editor appears completely unstyled
  - CSS classes from the Lexxy gem have no effect
components:
  - app/views/layouts/application.html.erb
  - lexxy gem asset files (lexxy.css, lexxy-editor.css, lexxy-content.css)
---

## Problem

After installing the Lexxy gem and loading the Lexxy JS, the editor toolbar renders as large raw unstyled symbols. The editor is functional but visually broken.

## Root Cause

The Lexxy gem ships its own CSS files in `app/assets/stylesheets/`:

```
lexxy.css           # entry point — @imports the two below
lexxy-editor.css    # toolbar and editor chrome styles
lexxy-content.css   # content area styles
```

Rails and Propshaft make these files **available** in the asset pipeline, but they do not automatically insert `<link>` tags for them. The developer must explicitly add `stylesheet_link_tag "lexxy"` to the layout. Without it, none of the editor's CSS loads, and the toolbar icons (which rely on CSS background images or icon fonts) fall back to their raw character representation.

This is distinct from the JS loading path: the Lexxy JS is loaded via importmap (`import "lexxy"` in `application.js`) and initializes the editor correctly — the editor is functional, just unstyled.

## Fix

Add `stylesheet_link_tag "lexxy"` to `app/views/layouts/application.html.erb`:

```erb
<head>
  ...
  <%= stylesheet_link_tag :app, "data-turbo-track": "reload" %>
  <%= stylesheet_link_tag "lexxy", "data-turbo-track": "reload" %>
  <%= javascript_importmap_tags %>
</head>
```

`lexxy.css` is the entry point and imports the rest:

```css
/* lexxy.css */
@import url("lexxy-content.css");
@import url("lexxy-editor.css");
```

Linking only `lexxy.css` is sufficient.

## Verify Assets Are Available

```bash
bin/rails assets:reveal | grep lexxy
# Should list: lexxy.css, lexxy-editor.css, lexxy-content.css, lexxy-variables.css
```

If the files are listed, they are in the load path and `stylesheet_link_tag "lexxy"` will resolve correctly.

## Detection

If a gem's styles are absent after installation:

1. View page source and look for a `<link href="...lexxy...">` tag in `<head>` — if missing, the stylesheet was never linked
2. Run `bin/rails assets:reveal | grep <gem-name>` to confirm the files are in the asset path
3. Check the gem's `app/assets/stylesheets/` directory for CSS files that need explicit linking

## Prevention Rule

> After adding any gem that ships its own CSS, explicitly add `stylesheet_link_tag "gem-name"` to the layout. Gem installation does not wire up stylesheets automatically.

## Note on Lexxy vs Trix

This project uses **Lexxy** as the rich text editor, replacing ActionText's default Trix editor. Do not add `javascript_include_tag "trix"` or `stylesheet_link_tag "trix"` — Lexxy handles its own JS via importmap and its own CSS via the link tag above.

The `app/assets/stylesheets/actiontext.css` file in this project provides ActionText content area styles — it is separate from Trix and remains needed for rendering saved ActionText content.
