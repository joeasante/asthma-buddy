import { Controller } from "@hotwired/stimulus"

// Shows an in-app toast when the element it's mounted on has
// data-toast-message and (optionally) data-toast-variant attributes.
// Turbo Stream responses set those attributes on the replaced flash div;
// Stimulus connect() fires on the newly inserted element and triggers the toast.
//
// Variants: "success" (default) | "notice" | "alert"
// Dismiss: auto after 4 s, or tap the × button.
export default class extends Controller {
  connect() {
    const message = this.element.dataset.toastMessage
    const variant = this.element.dataset.toastVariant || "success"
    if (!message) return
    this.#show(message, variant)
  }

  disconnect() {
    clearTimeout(this.#timer)
  }

  // Private

  #timer = null

  #show(message, variant) {
    const region = document.getElementById("toast-region")
    if (!region) return

    const toast = document.createElement("div")
    toast.className = `toast toast--${variant}`
    toast.setAttribute("role", "status")

    const msg = document.createElement("span")
    msg.className = "toast-message"
    msg.textContent = message

    const btn = document.createElement("button")
    btn.type = "button"
    btn.className = "toast-dismiss"
    btn.setAttribute("aria-label", "Dismiss notification")
    btn.innerHTML = `<svg width="14" height="14" viewBox="0 0 14 14" fill="none" aria-hidden="true">
      <path d="M1 1l12 12M13 1L1 13" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
    </svg>`
    btn.addEventListener("click", () => this.#dismiss(toast), { once: true })

    toast.append(msg, btn)
    region.appendChild(toast)

    // Trigger enter transition on next frame
    requestAnimationFrame(() => toast.classList.add("toast--visible"))

    this.#timer = setTimeout(() => this.#dismiss(toast), 4000)
  }

  #dismiss(toast) {
    clearTimeout(this.#timer)
    toast.classList.remove("toast--visible")
    toast.addEventListener("transitionend", () => toast.remove(), { once: true })
  }
}
