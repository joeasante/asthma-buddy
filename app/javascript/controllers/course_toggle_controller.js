import { Controller } from "@hotwired/stimulus"

// Toggles visibility of course date fields and inhaler-specific fields
// when the "This is a temporary course" checkbox is checked.
export default class extends Controller {
  static targets = ["courseFields", "inhalerFields", "dosesPerDayField", "checkbox"]

  connect() {
    this.toggle()
  }

  toggle() {
    const isCourse = this.checkboxTarget.checked

    // Show course date fieldset, hide inhaler-only fields
    this.courseFieldsTarget.hidden = !isCourse
    this.inhalerFieldsTarget.hidden = isCourse

    // Use native fieldset disabled to exclude course fields from submission when hidden
    const courseFieldset = this.courseFieldsTarget.querySelector("fieldset")
    if (courseFieldset) courseFieldset.disabled = !isCourse

    // Disable all inhaler inputs when hidden so they are excluded from submission
    this.inhalerFieldsTarget.querySelectorAll("input").forEach(input => {
      input.disabled = isCourse
    })
  }
}
