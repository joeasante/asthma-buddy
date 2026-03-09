---
status: diagnosed
trigger: "Flash message zone name not rendered in zone colour (green/yellow/red)"
created: 2026-03-07T00:00:00Z
updated: 2026-03-07T00:00:00Z
---

## Current Focus

hypothesis: confirmed — three independent deficiencies prevent coloured zone labels in flash
test: read all four named files end-to-end
expecting: root cause is combination of plain-text message + escaped output + no zone CSS classes
next_action: return diagnosis to caller

## Symptoms

expected: Zone label in flash ("Green Zone", "Yellow Zone", "Red Zone") renders with matching colour
actual: Zone label appears as plain, unstyled text — no colour applied
errors: none (no exception, just missing visual styling)
reproduction: save a peak flow reading when a personal best is set
started: unknown — likely never worked (design gap, not regression)

## Eliminated

- hypothesis: CSS custom properties (--severity-*) do not exist
  evidence: symptom_timeline.css defines --severity-mild (#2d8a4e), --severity-moderate (#c57a00), --severity-severe (#c0392b) plus .severity-label--mild/moderate/severe classes
  timestamp: 2026-03-07

- hypothesis: Turbo Stream does not update the flash area
  evidence: create.turbo_stream.erb uses turbo_stream.prepend "main-content" which injects the flash <p> into the correct DOM target
  timestamp: 2026-03-07

## Evidence

- timestamp: 2026-03-07
  checked: app/controllers/peak_flow_readings_controller.rb zone_flash_message (lines 46-52)
  found: returns a plain Ruby String — "Reading saved — Green Zone (92% of personal best)." — no HTML tags, no CSS classes
  implication: the zone word is not wrapped in any styled element

- timestamp: 2026-03-07
  checked: app/views/peak_flow_readings/create.turbo_stream.erb line 13
  found: <%= @flash_message %> — standard ERB output helper, which HTML-escapes its argument
  implication: even if zone_flash_message were changed to return an HTML string, it would be double-escaped and rendered as literal tag text unless .html_safe or raw() is used

- timestamp: 2026-03-07
  checked: app/views/layouts/application.html.erb line 48
  found: <%= notice %> — same plain ERB output, no raw() or html_safe call; flash notice path also cannot render HTML
  implication: the HTML path (format.html redirect) has the same escaping problem

- timestamp: 2026-03-07
  checked: app/assets/stylesheets/peak_flow.css
  found: no zone-specific CSS classes at all (.zone-green, .zone-yellow, .zone-red, etc.); file only defines form layout and input styles
  implication: even if HTML were emitted, there is no CSS class to apply the colour

- timestamp: 2026-03-07
  checked: app/assets/stylesheets/symptom_timeline.css
  found: .severity-label--mild / --moderate / --severe classes exist and map to the correct colours via CSS custom properties; also .severity-indicator--* classes
  implication: the colour system already exists but uses the symptom severity naming convention (mild/moderate/severe), not zone naming (green/yellow/red)

## Resolution

root_cause: |
  Three independent gaps combine to produce the symptom:

  1. zone_flash_message returns a plain Ruby String with no HTML markup.
     The zone name ("Green Zone", "Yellow Zone", "Red Zone") is bare text —
     no <span>, no class attribute.

  2. create.turbo_stream.erb emits @flash_message with the standard ERB
     escape helper (<%= %>), which would HTML-escape any tags even if they
     were present. The layout also uses <%= notice %> without raw()/html_safe.
     Neither rendering path can display HTML from the flash string.

  3. No CSS class targeting zone colour exists in peak_flow.css (or anywhere).
     The only colour classes are .severity-label--mild/moderate/severe in
     symptom_timeline.css, scoped to the symptom-severity naming convention,
     not to peak-flow zones.

fix: not applied (diagnose-only mode)
verification: not applied
files_changed: []
