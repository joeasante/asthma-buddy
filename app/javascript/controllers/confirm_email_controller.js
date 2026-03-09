import { Controller } from "@hotwired/stimulus"

// Guards the account-deletion dialog with an email confirmation step.
// The delete button starts disabled and is only enabled when the user types
// their email address exactly (compared case-sensitively via data-email value).
export default class extends Controller {
  static targets = ["dialog", "input", "button"]
  static values = { email: String }

  open() {
    this.dialogTarget.showModal()
  }

  dismiss() {
    this.dialogTarget.close()
    this.inputTarget.value = ""
    this.buttonTarget.disabled = true
  }

  // Close on backdrop click (click on the <dialog> element itself, not its content)
  backdropClick(event) {
    if (event.target === this.dialogTarget) this.dismiss()
  }

  check() {
    this.buttonTarget.disabled = this.inputTarget.value.trim() !== this.emailValue
  }
}
