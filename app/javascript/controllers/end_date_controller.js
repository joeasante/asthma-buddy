import { Controller } from "@hotwired/stimulus"

// Handles two concerns on the medical event form:
//
// 1. Hides the entire duration section (start→end dates + ongoing checkbox)
//    for point-in-time event types (GP appointment, medication change).
//    Types are passed from the server via the pointInTimeTypes Stimulus value
//    (data-end-date-point-in-time-types-value) so the list is defined once in Ruby.
// 2. Within the duration section, toggles the end date field on/off based
//    on the "Still ongoing" checkbox.

export default class extends Controller {
  static targets = ["eventTypeSelect", "durationSection", "checkbox", "endDateField"]
  static values = { pointInTimeTypes: Array }

  connect() {
    this.updateForEventType()
  }

  eventTypeChanged() {
    this.updateForEventType()
  }

  toggle() {
    const ongoing = this.checkboxTarget.checked
    this.endDateFieldTarget.hidden = ongoing
    const input = this.endDateFieldTarget.querySelector("input")
    if (input) {
      input.disabled = ongoing
      if (ongoing) input.value = ""
    }
  }

  // private

  updateForEventType() {
    if (!this.hasEventTypeSelectTarget) return

    const value = this.eventTypeSelectTarget.value
    const isPointInTime = this.pointInTimeTypesValue.includes(value)

    this.durationSectionTarget.hidden = isPointInTime
    this.durationSectionTarget.querySelectorAll("input").forEach(input => {
      input.disabled = isPointInTime
    })

    if (!isPointInTime) {
      this.toggle()
    }
  }
}
