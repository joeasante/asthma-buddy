import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  dismiss() {
    const el = this.element
    el.classList.add("cookie-notice--dismissed")
    // Fallback for reduced-motion or missing transition: remove after 400ms
    const fallback = setTimeout(() => el.remove(), 400)
    el.addEventListener("transitionend", () => {
      clearTimeout(fallback)
      el.remove()
    }, { once: true })
  }
}
