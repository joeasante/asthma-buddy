import { Controller } from "@hotwired/stimulus"

// Auto-submits a date range form when both start and end dates are filled.
// Eliminates the need for an explicit "Apply" button.
export default class extends Controller {
  static targets = ["start", "end"]

  check() {
    if (this.startTarget.value && this.endTarget.value) {
      this.element.requestSubmit()
    }
  }
}
