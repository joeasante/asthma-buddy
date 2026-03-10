import { Controller } from "@hotwired/stimulus"

// Keeps the Morning / Evening radio in sync with the recorded_at datetime field.
// Hour < 13 → Morning; 13:00 or later → Evening.
// Fires on every change to the datetime input, including the "Right now" shortcut.
export default class extends Controller {
  static targets = ["datetime", "morning", "evening"]

  sync() {
    const value = this.datetimeTarget.value
    if (!value) return

    // Parse hour directly from the datetime-local string ("YYYY-MM-DDTHH:MM")
    // to avoid timezone ambiguity from new Date().
    const hour = parseInt(value.slice(11, 13), 10)
    const isMorning = hour < 13

    this.morningTarget.checked = isMorning
    this.eveningTarget.checked = !isMorning
    this.morningTarget.dispatchEvent(new Event("change", { bubbles: true }))
  }
}
