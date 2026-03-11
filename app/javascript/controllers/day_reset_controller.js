import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { date: String }

  connect() {
    this.scheduleMidnightReload()
    this.startSafetyCheck()
    document.addEventListener("visibilitychange", this.handleVisibilityChange)
  }

  disconnect() {
    clearTimeout(this.midnightTimeout)
    clearInterval(this.safetyInterval)
    document.removeEventListener("visibilitychange", this.handleVisibilityChange)
  }

  handleVisibilityChange = () => {
    if (!document.hidden) this.checkDate()
  }

  scheduleMidnightReload() {
    const now = new Date()
    const nextMidnight = new Date(Date.UTC(
      now.getUTCFullYear(),
      now.getUTCMonth(),
      now.getUTCDate() + 1
    ))
    const msUntilMidnight = nextMidnight - now
    this.midnightTimeout = setTimeout(() => this.reload(), msUntilMidnight)
  }

  startSafetyCheck() {
    this.safetyInterval = setInterval(() => this.checkDate(), 60_000)
  }

  checkDate() {
    const today = new Date().toISOString().slice(0, 10)
    if (today !== this.dateValue) this.reload()
  }

  reload() {
    Turbo.visit(window.location.href, { action: "replace" })
  }
}
