import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  dismiss() {
    this.element.classList.add("cookie-notice--dismissed")
    // Remove after CSS transition completes
    this.element.addEventListener("transitionend", () => {
      this.element.remove()
    }, { once: true })
  }
}
