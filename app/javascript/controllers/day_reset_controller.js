import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { date: String }

  connect() {
    this.scheduleMidnightReload()
    document.addEventListener("visibilitychange", this.handleVisibilityChange)
  }

  disconnect() {
    clearTimeout(this.midnightTimeout)
    document.removeEventListener("visibilitychange", this.handleVisibilityChange)
  }

  handleVisibilityChange = () => {
    if (!document.hidden) this.checkDate()
  }

  scheduleMidnightReload() {
    const now = new Date()
    const nextMidnight = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1)
    const msUntilMidnight = nextMidnight - now
    this.midnightTimeout = setTimeout(() => this.reload(), msUntilMidnight)
  }

  checkDate() {
    const now = new Date()
    const today = [
      now.getFullYear(),
      String(now.getMonth() + 1).padStart(2, "0"),
      String(now.getDate()).padStart(2, "0")
    ].join("-")
    if (today !== this.dateValue) this.reload()
  }

  reload() {
    Turbo.visit(window.location.href, { action: "replace" })
  }
}
