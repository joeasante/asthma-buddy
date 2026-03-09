import { Controller } from "@hotwired/stimulus"

// Fills a datetime-local input with the current local time when the user
// taps "Right now". Works with any datetime-local field via data-now-target="input".
export default class extends Controller {
  static targets = ["input"]

  fill() {
    const now = new Date()
    // datetime-local expects "YYYY-MM-DDTHH:MM" in LOCAL time
    const pad = n => String(n).padStart(2, "0")
    const formatted =
      `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}` +
      `T${pad(now.getHours())}:${pad(now.getMinutes())}`
    this.inputTarget.value = formatted
    this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.inputTarget.dispatchEvent(new Event("input",  { bubbles: true }))
  }
}
