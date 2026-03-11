import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { datetime: String }

  connect() {
    this.update()
    this.interval = setInterval(() => this.update(), 60_000)
  }

  disconnect() {
    clearInterval(this.interval)
  }

  update() {
    const then = new Date(this.datetimeValue)
    const now  = new Date()
    const diffSeconds = Math.round((now - then) / 1000)

    this.element.textContent = this.format(diffSeconds)
  }

  format(seconds) {
    if (seconds < 60)          return "just now"
    if (seconds < 3600)        return `${Math.floor(seconds / 60)} minutes ago`
    if (seconds < 7200)        return "1 hour ago"
    if (seconds < 86400)       return `${Math.floor(seconds / 3600)} hours ago`
    if (seconds < 172800)      return "yesterday"
    if (seconds < 604800)      return `${Math.floor(seconds / 86400)} days ago`
    if (seconds < 1209600)     return "1 week ago"
    return `${Math.floor(seconds / 604800)} weeks ago`
  }
}
