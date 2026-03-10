import { Controller } from "@hotwired/stimulus"

// Toggles visibility of course date fields and hides doses_per_day
// when the "This is a temporary course" checkbox is checked.
export default class extends Controller {
  static targets = ["courseFields", "dosesPerDayField", "checkbox"]

  connect() {
    this.toggle()
  }

  toggle() {
    const isCourse = this.checkboxTarget.checked

    this.courseFieldsTarget.hidden = !isCourse
    this.dosesPerDayFieldTarget.hidden = isCourse

    // Use native fieldset disabled to exclude all controls from submission
    const courseFieldset = this.courseFieldsTarget.querySelector("fieldset")
    if (courseFieldset) courseFieldset.disabled = !isCourse

    // Disable the doses_per_day input when course is active
    const dosesInput = this.dosesPerDayFieldTarget.querySelector("input")
    if (dosesInput) dosesInput.disabled = isCourse
  }
}
