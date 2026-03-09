import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.boundClose = this.closeOnOutsideClick.bind(this)
    this.boundKeydown = this.closeOnEscape.bind(this)
  }

  disconnect() {
    document.removeEventListener("click", this.boundClose)
    document.removeEventListener("keydown", this.boundKeydown)
  }

  toggle(event) {
    event.stopPropagation()
    const menu = this.menuTarget
    if (menu.hidden) {
      menu.hidden = false
      document.addEventListener("click", this.boundClose)
      document.addEventListener("keydown", this.boundKeydown)
    } else {
      this.close()
    }
  }

  close() {
    this.menuTarget.hidden = true
    document.removeEventListener("click", this.boundClose)
    document.removeEventListener("keydown", this.boundKeydown)
  }

  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  closeOnEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
}
