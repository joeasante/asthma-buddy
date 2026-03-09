import { Controller } from "@hotwired/stimulus"

// Closes the overflow menu and log panel when a click occurs outside the med-row.
// Also closes overflow when log panel opens, and vice versa.
export default class extends Controller {
  static targets = ["overflow", "logPanel"]

  connect() {
    this.#handleOutsideClick = this.#handleOutsideClick.bind(this)
    document.addEventListener("click", this.#handleOutsideClick)
  }

  disconnect() {
    document.removeEventListener("click", this.#handleOutsideClick)
  }

  // Close overflow when log panel is opened, so only one panel is open at once
  logPanelToggle() {
    if (this.hasOverflowTarget && this.overflowTarget.open) {
      this.overflowTarget.open = false
    }
  }

  // Close log panel when overflow is opened
  overflowToggle() {
    if (this.hasLogPanelTarget && this.logPanelTarget.open) {
      this.logPanelTarget.open = false
    }
  }

  // Private

  #handleOutsideClick = null

  #handleOutsideClick(event) {
    if (this.element.contains(event.target)) return

    if (this.hasOverflowTarget && this.overflowTarget.open) {
      this.overflowTarget.open = false
    }
    if (this.hasLogPanelTarget && this.logPanelTarget.open) {
      this.logPanelTarget.open = false
    }
  }
}
