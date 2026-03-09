---
title: "Failed to resolve module specifier" after gem install (stale importmap cache)
category: build-errors
tags: [importmap, javascript, gem-assets, rails-server, caching, turbo, propshaft]
symptoms:
  - Browser console shows "Failed to resolve module specifier 'gem-name'"
  - application.js fails to load entirely (all Turbo/Stimulus features break)
  - bin/importmap json shows the correct mapping but the browser cannot find it
  - JS-dependent features (confirmation dialogs, Turbo Streams, Stimulus controllers) silently stop working
components:
  - config/importmap.rb
  - Rails server process (in-memory importmap cache)
  - app/views/layouts/application.html.erb (importmap script tag)
  - gem JavaScript assets (e.g., lexxy.js)
---

## Problem

After adding or updating a gem that ships JavaScript assets, the browser console shows:

```
Uncaught TypeError: Failed to resolve module specifier "gem-name".
Relative references must start with either "/", "./", or "../".
```

`application.js` fails to load entirely because ES module resolution fails if **any** import cannot be resolved. This breaks all Turbo and Stimulus functionality — confirmation dialogs don't fire, Turbo Streams don't update, Stimulus controllers don't initialize.

## Root Cause

The Rails server caches its importmap in memory at startup. After installing or updating a gem that provides JavaScript assets, the **running server** continues serving the old importmap that does not include the new gem's entry. The browser receives HTML with an `<script type="importmap">` block that is missing the new module mapping.

`bin/importmap json` regenerates the importmap fresh on each CLI invocation, so it correctly shows the new mapping — but the running server is still on the old cached version.

## Diagnostic

Run the CLI to see the correct importmap:

```bash
bin/importmap json | grep gem-name
# Shows: "gem-name": "/assets/gem-name-abc123.js"
```

If the entry appears here but the browser reports it cannot be found, the running server is serving a stale importmap. A server restart will fix it.

## Fix

Restart the Rails development server:

```bash
# Stop with Ctrl+C, then:
bin/rails server
```

After restart, the server re-evaluates `config/importmap.rb` and rescans Propshaft's asset paths. The browser will receive the correct importmap on the next page load.

## Critical Pitfall: Do Not Use `bin/importmap pin`

Running `bin/importmap pin gem-name` to work around the missing entry **downloads the package from a CDN** (jspm.io) at the latest npm version, which is typically different from — and incompatible with — the version shipped by the gem.

For example, the `lexxy` gem ships version `0.1.26.beta`, but `bin/importmap pin lexxy` downloaded `lexxy@0.4.0` from npm — a completely different package (a generic lexer library, not the Rails editor).

**To undo an accidental `bin/importmap pin`:**

1. Restore `config/importmap.rb` — revert the changed line back to `pin "gem-name", to: "gem-name.js"`
2. Delete the downloaded file: `rm vendor/javascript/gem-name.js`
3. Restart the server

## Prevention Rule

> After adding a gem that provides JavaScript assets, always restart the development server. Never use `bin/importmap pin` for gem-provided JS — it downloads from the CDN at a potentially incompatible version.

**Use `bin/importmap pin` only for packages that are not provided by a gem** (i.e., standalone npm packages you want to vendor locally).

## How Gem JS Assets Work

Gems that ship JavaScript register their `app/assets/javascript/` directory with Rails' asset pipeline. Propshaft makes these files available at `/assets/gem-name-<digest>.js`. The gem also adds its pin to `config/importmap.rb` (or the developer adds it manually). When the server starts, importmap-rails resolves all pins against Propshaft's asset paths and caches the result — which is why a restart is required after changes.

## Tests

System tests that exercise JS-dependent features provide the best safety net:

```bash
# Run system tests after every gem addition that ships JS
bin/rails test:system
```

If a system test that previously passed starts failing after adding a gem, a server restart is the first thing to try before investigating further.
