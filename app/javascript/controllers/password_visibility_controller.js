import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "toggle"]

  toggle() {
    const isPassword = this.inputTarget.type === "password"
    this.inputTarget.type = isPassword ? "text" : "password"
    this.toggleTarget.setAttribute("aria-label", isPassword ? "Hide password" : "Show password")
    this.toggleTarget.querySelector(".eye-icon--show").hidden = !isPassword
    this.toggleTarget.querySelector(".eye-icon--hide").hidden = isPassword
  }
}
