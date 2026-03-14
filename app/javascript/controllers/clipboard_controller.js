import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { target: String }

  copy() {
    const element = document.getElementById(this.targetValue)
    if (!element) return

    const text = element.textContent
    const original = this.element.textContent

    navigator.clipboard.writeText(text).then(() => {
      this.element.textContent = "Copied!"
      setTimeout(() => { this.element.textContent = original }, 2000)
    }).catch(() => {
      this.element.textContent = "Failed to copy"
      setTimeout(() => { this.element.textContent = original }, 2000)
    })
  }
}
