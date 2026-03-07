import { Controller } from "@hotwired/stimulus"

// Replaces Turbo's native browser confirm() with an in-app <dialog> modal.
// Mount on a wrapper element that contains the <dialog>; Turbo.config.confirmMethod
// is overridden on connect so all data-turbo-confirm actions use this modal.
export default class extends Controller {
  static targets = ["dialog", "message"]

  connect() {
    Turbo.config.confirmMethod = (message) => this.#ask(message)
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
