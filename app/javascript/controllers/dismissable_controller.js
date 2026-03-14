import { Controller } from "@hotwired/stimulus"

// Generic dismissable banner — sets a cookie so it stays hidden.
// Usage: data-controller="dismissable"
//        data-dismissable-cookie-value="cookie_name"
//        data-dismissable-cookie-token-value="unique_token"
export default class extends Controller {
  static values = { cookie: String, cookieToken: String }

  dismiss() {
    // Set cookie that expires at end of current week (Sunday midnight)
    const expires = new Date()
    expires.setDate(expires.getDate() + (7 - expires.getDay()))
    expires.setHours(23, 59, 59, 999)

    document.cookie = `${this.cookieValue}=${this.cookieTokenValue}; path=/; expires=${expires.toUTCString()}; SameSite=Lax`

    const el = this.element
    el.style.transition = "opacity 0.2s ease, max-height 0.3s ease"
    el.style.opacity = "0"
    el.style.maxHeight = el.offsetHeight + "px"
    requestAnimationFrame(() => {
      el.style.maxHeight = "0"
      el.style.overflow = "hidden"
      el.style.padding = "0"
      el.style.margin = "0"
    })
    setTimeout(() => el.remove(), 350)
  }
}
