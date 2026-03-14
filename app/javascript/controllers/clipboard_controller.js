import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { target: String }

  copy() {
    const element = document.getElementById(this.targetValue)
    if (!element) return

    navigator.clipboard.writeText(element.textContent).then(() => {
      const original = this.element.textContent
      this.element.textContent = "Copied!"
      setTimeout(() => { this.element.textContent = original }, 2000)
    })
  }
}
