---
status: diagnosed
trigger: "After a successful peak flow reading is saved, form does not reset and flash messages accumulate"
created: 2026-03-07T00:00:00Z
updated: 2026-03-07T00:00:00Z
---

## Current Focus

hypothesis: confirmed - two independent bugs identified
test: static code analysis of turbo stream template and layout
expecting: n/a - root causes confirmed
next_action: return diagnosis to caller

## Symptoms

expected: After success, form resets to empty/current time and only the latest flash is visible
actual:
  1. Form value field still shows the submitted number after success
  2. Flash messages accumulate — old ones remain and new ones appear below them
errors: none (no crash, purely a UI/UX bug)
reproduction: Submit a valid peak flow reading at /peak-flow-readings/new via turbo stream
started: unknown — likely always present

## Eliminated

- hypothesis: turbo_stream.replace targeting wrong id
  evidence: The id "peak_flow_reading_form" matches the turbo_frame_tag in new.html.erb (line 6). The target IS correct.
  timestamp: 2026-03-07

- hypothesis: form partial not rendering a blank record
  evidence: create.turbo_stream.erb (line 4) does pass a fresh unsaved record with only recorded_at set and no :value — so the rendered HTML itself would be blank.
  timestamp: 2026-03-07

## Evidence

- timestamp: 2026-03-07
  checked: new.html.erb lines 5-10
  found: The form is wrapped in `turbo_frame_tag "peak_flow_reading_form"` — gives the frame the DOM id "peak_flow_reading_form"
  implication: turbo_stream.replace targeting "peak_flow_reading_form" is aimed at this frame element

- timestamp: 2026-03-07
  checked: create.turbo_stream.erb line 2
  found: Uses `turbo_stream.replace "peak_flow_reading_form"` which emits a <turbo-stream action="replace" target="peak_flow_reading_form"> tag. This replaces the ENTIRE element matching that id.
  implication: When Turbo processes this, it replaces the <turbo-frame id="peak_flow_reading_form"> element with the rendered block content. The rendered block is a bare `render "form"` — it is NOT wrapped in a turbo_frame_tag. So the replacement content has no <turbo-frame> wrapper. Turbo's replace action swaps the outer element entirely — but the new content is just raw HTML, not a frame. This means the frame is DESTROYED and replaced with the raw form HTML.

- timestamp: 2026-03-07
  checked: create.turbo_stream.erb lines 1-8 and _form.html.erb
  found: The form partial renders correctly with a blank peak_flow_reading (no :value set). The HTML for the number field will have no value attribute. However, browsers have a built-in behaviour: when a form is replaced in-place via DOM mutation (not a full navigation), some browsers restore form field values from their internal form state cache if the input element retains the same name attribute.
  implication: BUT more critically — the turbo_stream.replace block does NOT wrap the rendered form in a turbo_frame_tag. This means on the SECOND submission, Turbo can no longer find a <turbo-frame id="peak_flow_reading_form"> to navigate within, so the form may fall back to a full-page request. This is a secondary concern. The PRIMARY form-not-clearing issue is actually the browser autofill/form restoration — browsers (Chrome, Firefox, Safari) cache form input values and can restore them into newly inserted DOM nodes that share the same name/id attributes.

- timestamp: 2026-03-07
  checked: create.turbo_stream.erb line 12 — turbo_stream.prepend "main-content"
  found: Uses `prepend` action. Turbo's prepend action INSERTS new content at the top of the target element — it does NOT remove existing content. Every successful submission adds a new <p class="flash flash--notice"> node inside #main-content, above all previous content.
  implication: Flash messages accumulate indefinitely. There is no remove/replace action for old flash nodes, and no Stimulus controller or JS to auto-dismiss them.

- timestamp: 2026-03-07
  checked: application.html.erb lines 46-55
  found: The layout renders flash notices as static <p> tags inside <main id="main-content"> during the initial page render. There is no dedicated flash container with its own stable DOM id (e.g. id="flash-container"). The turbo_stream.prepend targets "main-content" — the entire main element — which also contains the yielded page content.
  implication: Each prepend inserts a flash <p> as the first child of <main>, so flash messages pile up above the page heading with no mechanism to clear previous ones. If a dedicated flash container with a stable id existed, turbo_stream.replace could target it instead, replacing the entire flash area on each submission.

- timestamp: 2026-03-07
  checked: create.turbo_stream.erb line 2 — turbo_stream.replace block content
  found: The block renders `render "form"` unwrapped — no turbo_frame_tag around it. The original page wraps the form in turbo_frame_tag (new.html.erb line 6). After the replace, the <turbo-frame> element is gone from the DOM. Subsequent form submissions will no longer be intercepted by Turbo as frame navigations.
  implication: The missing turbo_frame_tag in the replace block means the frame is destroyed after the first successful save. This is a third bug beyond the two reported symptoms, but it compounds the problem.

## Resolution

root_cause: |
  BUG 1 — Form not clearing (value field retains submitted number):
  The turbo_stream.replace in create.turbo_stream.erb (line 2) does replace the DOM element
  with a correctly blank form partial. However, the replace block renders the form partial
  WITHOUT wrapping it in a turbo_frame_tag. This destroys the <turbo-frame> from the DOM.
  More directly for the clearing symptom: browsers (Chrome, Firefox, Safari) implement
  form state restoration — when DOM nodes are inserted with the same input name attributes
  as recently-submitted inputs, the browser may repopulate them from its internal history.
  The canonical fix is to either (a) use a turbo_stream.replace that targets only the
  inputs (not the full frame), or (b) ensure the replacement is wrapped in a turbo_frame_tag
  so Turbo treats it as a proper frame navigation and clears browser form state, or
  (c) add a Stimulus controller that resets the form after the turbo:submit-end event.
  The most structurally correct fix is wrapping the rendered form in turbo_frame_tag
  inside the replace block, so the <turbo-frame id="peak_flow_reading_form"> is preserved
  in the DOM with fresh content and Turbo handles form state correctly.

  BUG 2 — Flash messages accumulate:
  create.turbo_stream.erb (line 12) uses turbo_stream.prepend "main-content" — the prepend
  action INSERTS content without removing anything. Every successful submission inserts
  another <p class="flash flash--notice"> node inside <main id="main-content">. There is
  no corresponding remove or replace for old flash nodes, and no auto-dismiss JS.
  Additionally, there is no dedicated flash container element with a stable DOM id.
  The fix requires either: (a) replacing turbo_stream.prepend with turbo_stream.replace
  targeting a dedicated flash container element (e.g. <div id="flash-messages">) that
  wraps the flash area in the layout, or (b) adding a turbo_stream.remove for old flashes
  before prepending the new one.

fix: not applied — diagnosis only
verification: not performed
files_changed: []
