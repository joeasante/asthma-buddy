---
status: pending
priority: p3
issue_id: "255"
tags: [code-review, stimulus, javascript, robustness]
dependencies: []
---

# Stimulus `querySelectorAll("input")` Fragile for Disabling Course Fields

## Problem Statement

`course_toggle_controller.js` disables course date inputs by selecting all `input` elements inside the `courseFields` target. If a `<select>` or `<textarea>` is ever added to the course fields section, it will not be disabled and its value will be submitted silently when the checkbox is unchecked.

Additionally, the two disable operations use inconsistent granularity (`querySelectorAll` vs `querySelector`) and opposing boolean expressions (`!isCourse` vs `isCourse`), requiring mental inversion to read.

## Findings

`app/javascript/controllers/course_toggle_controller.js` lines 18–21:

```js
this.courseFieldsTarget.querySelectorAll("input").forEach(input => {
  input.disabled = !isCourse
})
this.dosesPerDayFieldTarget.querySelector("input").disabled = isCourse
```

The native HTML approach for excluding all controls from submission is `fieldset[disabled]` — a disabled fieldset excludes all descendant form controls regardless of type (input, select, textarea, button).

Confirmed by: kieran-rails-reviewer.

## Proposed Solutions

### Option A — Use `fieldset[disabled]` attribute *(Recommended)*

```js
toggle() {
  const isCourse = this.checkboxTarget.checked
  this.courseFieldsTarget.hidden = !isCourse
  this.dosesPerDayFieldTarget.hidden = isCourse

  const courseFieldset = this.courseFieldsTarget.querySelector("fieldset")
  if (courseFieldset) courseFieldset.disabled = !isCourse

  const dosesInput = this.dosesPerDayFieldTarget.querySelector("input")
  if (dosesInput) dosesInput.disabled = isCourse
}
```

Pros: native HTML behaviour, handles all control types, spec-compliant
Cons: requires a `<fieldset>` wrapper inside `courseFields` (which already exists: `field-group--course`)

### Option B — Extract private helpers to clarify intent

```js
toggle() {
  const isCourse = this.checkboxTarget.checked
  this.#setSection(this.courseFieldsTarget, isCourse)
  this.#setSection(this.dosesPerDayFieldTarget, !isCourse)
}

#setSection(el, enabled) {
  el.hidden = !enabled
  el.querySelectorAll("input").forEach(input => input.disabled = !enabled)
}
```

Pros: removes the mental inversion burden, symmetric logic
Cons: still `querySelectorAll("input")` — doesn't handle select/textarea

## Recommended Action

Option A — use the fieldset's native disabled attribute. The fieldset already exists in the form. This is a small change with stronger guarantees.

## Technical Details

- **Affected file:** `app/javascript/controllers/course_toggle_controller.js`

## Acceptance Criteria

- [ ] Course fieldset is disabled (not just inputs) when checkbox is unchecked
- [ ] A `<select>` added to course fields would automatically be excluded from submission
- [ ] Existing system test for course toggle still passes

## Work Log

- 2026-03-10: Found by kieran-rails-reviewer during Phase 18 code review
