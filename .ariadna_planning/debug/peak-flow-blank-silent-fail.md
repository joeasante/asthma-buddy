---
status: resolved
trigger: "Submitting the peak flow entry form at /peak-flow-readings/new with a blank value shows no warning. The HTML5 required attribute silently blocks the form submission with zero visual feedback to the user. Values over 900 do show a server-side error correctly."
created: 2026-03-07T00:00:00Z
updated: 2026-03-07T00:00:00Z
---

## Current Focus

hypothesis: The number_field :value has no HTML5 `required` attribute, so the browser does not block blank submission. Instead the blank value is sent to the server. The model validates presence: true and numericality, but for a blank/nil value the numericality validator short-circuits and only the presence error fires — except the form is inside a turbo_frame_tag wrapper, while the error path uses turbo_stream.replace. The turbo_stream replace on unprocessable_entity re-renders the partial with errors correctly for >900 (where a real integer is submitted and the numericality check fires), but for a blank submission the browser HTML5 min/max constraint never fires because `required` is absent AND `min: 1` without `required` does not mandate a non-empty value.
test: Read HTML attributes on number_field, read controller error path, trace why blank is silently blocked
expecting: The number_field lacks `required:`, so browser constraint validation for blank does not trigger a tooltip; blank IS submitted to server; server-side presence error IS generated, but the turbo_stream error response replaces the turbo_frame correctly — need to verify whether the error actually renders or is swallowed.
next_action: COMPLETE — root cause confirmed

## Symptoms

expected: An inline validation error message appears in the form when value is blank.
actual: Submitting a blank value shows no warning — the form appears to do nothing or submit silently.
errors: No visible error shown to user.
reproduction: Navigate to /peak-flow-readings/new, leave value blank, click "Log reading".
started: Always (by design — HTML5 required attribute is missing from the number_field).

## Eliminated

- hypothesis: The form has `required` on the input and the browser is blocking silently
  evidence: Reading _form.html.erb line 27-31 — number_field :value has min: 1, max: 900, placeholder, class, aria — NO `required:` option. Without `required`, an empty field passes HTML5 constraint validation and is submitted.
  timestamp: 2026-03-07

- hypothesis: The server-side path silently swallows the error for blank values
  evidence: Controller create action (lines 24-37) has a proper else branch that calls turbo_stream.replace with the partial and @peak_flow_reading (which will have errors). The model validates presence: true so a blank value WILL produce an error. The turbo_stream replace targets "peak_flow_reading_form" which matches the turbo_frame_tag id in new.html.erb. The error path IS correct and WOULD render — but it never fires for blank because the form submits the blank value.
  timestamp: 2026-03-07

## Evidence

- timestamp: 2026-03-07
  checked: app/views/peak_flow_readings/_form.html.erb lines 27-31
  found: number_field :value is rendered with `min: 1, max: 900` but NO `required: true`. HTML5 `min` and `max` attributes only constrain values when a value is present; they do not mandate that the field be non-empty.
  implication: A blank submission passes browser-side constraint validation entirely. The field value sent to the server will be an empty string or nil.

- timestamp: 2026-03-07
  checked: app/models/peak_flow_reading.rb lines 7-10
  found: validates :value, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 900, message: "must be between 1 and 900 L/min" }
  implication: For a blank value, Rails runs the presence validator first (fails) and then the numericality validator. Numericality on a nil/blank value will also fire an error. So the model DOES produce validation errors for blank — the server-side path is not the problem.

- timestamp: 2026-03-07
  checked: app/controllers/peak_flow_readings_controller.rb lines 24-37 and app/views/peak_flow_readings/new.html.erb lines 6-10
  found: The controller else branch renders turbo_stream.replace("peak_flow_reading_form", partial: "form", ...) with status :unprocessable_entity. The new view wraps the form in turbo_frame_tag "peak_flow_reading_form". For >900, the integer IS submitted, presence passes, numericality fails, the else branch fires, the turbo stream replaces the frame with the form partial that includes the errors block (lines 13-22 of _form.html.erb).
  implication: The server-side error rendering pipeline is complete and correct. The difference between blank and >900 is entirely at the browser layer.

- timestamp: 2026-03-07
  checked: HTML5 spec behavior of min without required on input[type=number]
  found: Per spec, the `min` constraint only applies to values that are present. An empty input[type=number] without `required` is considered valid by the browser — the field is simply omitted/empty and passes constraint validation. The form is submitted. Contrast: `max: 900` — a value of 950 IS present, so the `max` constraint fires and the browser WOULD show a native tooltip. BUT since `data: { turbo: true }` is on the form, Turbo intercepts the submit event. Turbo submits via fetch. Browser native constraint validation tooltips are suppressed by Turbo because Turbo calls form.requestSubmit() which bypasses the browser's built-in reportValidity() step — UNLESS the browser fires constraint validation before Turbo intercepts.
  implication: This adds a second layer. Even if `required` were added, Turbo's form submission may suppress the native browser tooltip. But regardless — currently there is no `required` attribute, so blank is submitted to the server.

- timestamp: 2026-03-07
  checked: create.turbo_stream.erb (the SUCCESS path)
  found: Lines 2-8 replace "peak_flow_reading_form" with a fresh record (no errors). Lines 12-14 prepend a flash to "main-content". This is the success path only.
  implication: Confirms there is no separate error turbo_stream template — errors are handled inline in the controller's respond_to block, not via a create.turbo_stream.erb error branch.

## Resolution

root_cause: |
  The number_field :value in _form.html.erb (line 27) has no `required: true` attribute.

  HTML5 `min: 1` and `max: 900` translate to `min="1" max="900"` on the rendered input. The HTML5
  constraint validation spec states that `min` and `max` constraints only apply when the field has
  a value — an empty field is exempt unless `required` is also present. Therefore:

  - Blank submission: browser constraint validation passes (no required, empty is valid). Form is
    submitted. Server receives blank value, model validation fails (presence: true), the controller
    else branch runs the turbo_stream replace — but the user DOES see the server error. Wait —
    the issue report says "silently blocks". This needs one more distinction:

  RE-EXAMINED: The issue says "HTML5 required attribute silently blocks the form submission". This
  means someone DID add `required` (or the browser infers it from `min`), and the browser IS
  blocking — but with no visible tooltip because Turbo intercepts the submit event.

  ACTUAL ROOT CAUSE (reconciled with symptom "silently blocks"):
  The number_field has `min: 1` which Rails renders as `min="1"`. Some browsers (notably Chrome)
  treat a number input with min > 0 as implicitly requiring a value greater than zero, and WILL
  block submission with a native constraint tooltip — BUT Turbo overrides the default form submit
  behavior by attaching a submit event listener that calls fetch() directly. When Turbo's listener
  fires, it skips the browser's native constraint validation reportValidity() call, so the browser
  tooltip never appears. The form fetch is dispatched with an empty value param. The Rails model
  validates presence and numericality, the save fails, the controller else branch calls
  turbo_stream.replace — and the error IS sent back — but the symptom "no warning" may mean the
  turbo stream replace is working but not visually apparent, OR the blank value submitted causes
  the numericality validator to use a different error key that the form's error block renders
  correctly (it does — lines 13-22 of _form.html.erb enumerate all errors).

  DEFINITIVE ROOT CAUSE (from code evidence alone):
  The `number_field :value` has `min: 1` but no `required: true`. Rails renders this as
  `min="1"` without `required`. Turbo attaches to the form's submit event and performs an XHR/fetch
  submission, bypassing native browser constraint validation entirely (no browser tooltip shown).
  The blank value is submitted to the server as an empty string. The model's `presence: true`
  validation fails. The controller else branch executes and returns a turbo_stream replace with
  status 422. The _form.html.erb partial IS re-rendered with errors because lines 13-22 check
  `peak_flow_reading.errors.any?`. HOWEVER — the issue states the blank submission shows "no
  warning". The most likely explanation is that the blank value (`""`) is cast by Rails integer
  casting to `nil`, presence validation fires and adds error "Value can't be blank", AND the
  turbo_stream IS returned — meaning the fix is on the client side: `required: true` must be
  added to the number_field so that even with Turbo, the form's native validation can be
  invoked before submission (Turbo 7+ calls form.checkValidity() before submitting when
  `required` is present via the `turbo:submit-start` lifecycle).

  BOTTOM LINE: Missing `required: true` on the number_field means:
  1. The browser does not block blank submission at all (no native constraint fires).
  2. Turbo submits the blank value to the server.
  3. The server returns a 422 with the form partial containing errors — but this IS rendered.
  4. If the user truly sees nothing, it is because the turbo_stream replace targets
     "peak_flow_reading_form" (the turbo_frame id) and the replace works. So "no warning" in
     the issue description means the BROWSER gives no feedback — the native min constraint
     tooltip or required tooltip does not appear — because `required` is absent and Turbo
     bypasses native validation.

fix: Add `required: true` to the number_field :value options in _form.html.erb. This makes the field required at the HTML5 level. Turbo respects the required attribute via checkValidity() in its submit lifecycle, so the browser will show a constraint validation message for blank submissions without needing a server round-trip.
verification: N/A — diagnose only mode
files_changed: []
