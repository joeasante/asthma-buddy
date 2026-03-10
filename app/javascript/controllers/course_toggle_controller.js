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

    // Disable hidden inputs so they are excluded from form submission
    this.courseFieldsTarget.querySelectorAll("input").forEach(input => {
      input.disabled = !isCourse
    })
    this.dosesPerDayFieldTarget.querySelector("input").disabled = isCourse
  }
}
