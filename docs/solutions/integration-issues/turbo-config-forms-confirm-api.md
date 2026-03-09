---
title: "Turbo confirm() dialog not overriding with custom Stimulus controller"
date: "2026-03-07"
problem_type: "integration-issue"
component: "Turbo.js + Stimulus controller + custom confirmation dialog"
symptoms:
  - "Browser's native confirm() dialog appearing despite implementing a custom <dialog> modal"
  - "Stimulus controller loads and executes correctly but does not intercept Turbo form submissions"
  - "Custom <dialog> element never displayed to the user"
tags:
  - "turbo-rails"
  - "stimulus"
  - "dialog"
  - "forms"
  - "api-mismatch"
severity: "medium"
status: "solved"
related:
  - "ui-bugs/turbo-confirm-ignored-on-button-to.md"
  - "ui-bugs/turbo-hotwire-dom-targeting-and-frame-rendering.md"
---

# Turbo 2.x: Correct API for Custom Confirm Dialog

The Turbo 2.x API for overriding the confirmation dialog is `Turbo.config.forms.confirm`, not `Turbo.config.confirmMethod`. Setting the wrong property is a **silent failure** — no error is thrown, no warning logged, and the browser's native `window.confirm()` continues to fire.

---

## Root Cause & Solution

**Root cause:** `Turbo.config.confirmMethod` does not exist in Turbo 2.x. Assigning to it simply adds an unused key to the config object — JavaScript does not throw when you assign to a non-existent property. Turbo internally reads only `config.forms.confirm`, so the override is silently ignored.

The deprecated `Turbo.setConfirmMethod()` still works (it proxies to `config.forms.confirm` with a `console.warn`), but neither it nor the wrong property give any indication of failure.

### Wrong code
```js
connect() {
  Turbo.config.confirmMethod = (message) => this.#ask(message)
  //                ^^^^^^^^^^^^ does not exist — silently ignored
}
```

### Correct code (Turbo 2.x)
```js
connect() {
  Turbo.config.forms.confirm = (message) => this.#ask(message)
  //                ^^^^^^^^^^^^^^^^^^^^^  correct property
}
```

### API history

| Turbo version | API |
|--------------|-----|
| 1.x | `Turbo.setConfirmMethod(fn)` |
| 2.x (current) | `Turbo.config.forms.confirm = fn` |
| 2.x (deprecated) | `Turbo.setConfirmMethod(fn)` — still works, logs `console.warn` |

---

## Full Working Implementation

### Stimulus controller (`app/javascript/controllers/confirm_controller.js`)

```js
import { Controller } from "@hotwired/stimulus"

// Replaces Turbo's native browser confirm() with an in-app <dialog> modal.
// Mount on a wrapper element that contains the <dialog>; Turbo.config.forms.confirm
// is overridden on connect so all data-turbo-confirm actions use this modal.
export default class extends Controller {
  static targets = ["dialog", "message"]

  connect() {
    Turbo.config.forms.confirm = (message) => this.#ask(message)
  }

  accept() {
    this.dialogTarget.close()
    this.#resolve(true)
  }

  dismiss() {
    this.dialogTarget.close()
    this.#resolve(false)
  }

  // Close on backdrop click
  backdropClick(event) {
    if (event.target === this.dialogTarget) this.dismiss()
  }

  // Private
  #resolve = null

  #ask(message) {
    this.messageTarget.textContent = message
    this.dialogTarget.showModal()
    return new Promise((resolve) => { this.#resolve = resolve })
  }
}
```

The handler must return a `Promise<boolean>` — Turbo awaits it before deciding whether to submit.

### Layout (`app/views/layouts/application.html.erb`)

```erb
<body data-controller="confirm">
  <dialog class="confirm-dialog"
          data-confirm-target="dialog"
          data-action="click->confirm#backdropClick">
    <p class="confirm-dialog-message" data-confirm-target="message"></p>
    <div class="confirm-dialog-actions">
      <button class="btn-confirm-cancel" data-action="confirm#dismiss">Cancel</button>
      <button class="btn-confirm-delete" data-action="confirm#accept">Delete</button>
    </div>
  </dialog>
  ...
</body>
```

### Delete button (`_timeline_row.html.erb`)

No change needed to the view — `data-turbo-confirm` wires up automatically:

```erb
<%= button_to "Delete", symptom_log_path(symptom_log), method: :delete,
      class: "btn-delete",
      form: { data: { turbo: true, turbo_confirm: "Delete this entry?" } } %>
```

Note: `turbo_confirm` must be on the `form:` option, not the top-level `data:` option. See [`ui-bugs/turbo-confirm-ignored-on-button-to.md`](../ui-bugs/turbo-confirm-ignored-on-button-to.md).

---

## Prevention Strategies

### How to Verify the API

**Check the gem source directly — not blog posts.**

```bash
# Find the installed gem path
bundle show turbo-rails

# Search for the confirm config in source
grep -n "forms.confirm\|confirmMethod" $(bundle show turbo-rails)/app/assets/javascripts/turbo.js
```

Or verify at runtime in browser DevTools:
```js
// After page load, check if your override took effect
console.log(typeof Turbo.config.forms.confirm)
// → "function" if override succeeded
// → "undefined" (default) or wrong function if it failed silently
```

### Detecting Silent Failures

**The telltale sign:** Browser's native confirm dialog appears instead of your custom modal. No JS errors or console warnings accompany this.

Add an assertion in the controller to catch it during development:

```js
connect() {
  const confirmFn = (message) => this.#ask(message)
  Turbo.config.forms.confirm = confirmFn

  // Verify override took effect
  if (Turbo.config.forms.confirm !== confirmFn) {
    console.error("Turbo confirm override failed — check API version compatibility")
  }
}
```

### Code Review Checklist

- [ ] Confirm Turbo version: `bundle show turbo-rails` — 2.x requires `Turbo.config.forms.confirm`
- [ ] The override is set during `connect()`, not in a top-level script that may run before Turbo loads
- [ ] The handler returns `Promise<boolean>` (not just `boolean`) — Turbo `await`s it
- [ ] `turbo_confirm` is on the `form:` option of `button_to`, not the `data:` option
- [ ] There is a system test that asserts the *custom dialog* appears (not just that the action succeeds)

### System Test Pattern

```ruby
test "delete shows custom confirm dialog" do
  sign_in_as @alice
  visit symptom_logs_url

  within("##{dom_id(symptom_logs(:alice_wheezing))}") do
    click_button "Delete"
  end

  # Assert custom dialog is open — if native dialog fired instead, this fails
  assert_selector "dialog.confirm-dialog[open]"
  assert_text "Delete this entry?"

  click_button "Delete"  # button inside the dialog
  assert_no_selector "##{dom_id(symptom_logs(:alice_wheezing))}"
end
```

If the native dialog fires instead of the custom one, `assert_selector "dialog.confirm-dialog[open]"` will fail, making the regression immediately visible.

---

## Related Documentation

- [`ui-bugs/turbo-confirm-ignored-on-button-to.md`](../ui-bugs/turbo-confirm-ignored-on-button-to.md) — `data-turbo-confirm` must be on the `<form>`, not the `<button>`; use `form: { data: { turbo_confirm: "..." } }` with `button_to`
- [`ui-bugs/turbo-hotwire-dom-targeting-and-frame-rendering.md`](../ui-bugs/turbo-hotwire-dom-targeting-and-frame-rendering.md) — Turbo Stream DOM targeting, frame scope, and datetime input patterns
