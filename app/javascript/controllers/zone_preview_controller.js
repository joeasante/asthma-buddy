import { Controller } from "@hotwired/stimulus"

// Shows a real-time zone classification as the user types their peak flow value.
// Requires data-zone-preview-personal-best-value set to the user's PB (0 if unset).
export default class extends Controller {
  static targets = ["input", "preview"]
  static values  = { personalBest: Number }

  // Thresholds match PeakFlowReading::GREEN_ZONE_THRESHOLD / YELLOW_ZONE_THRESHOLD
  static GREEN  = 80
  static YELLOW = 50

  connect() {
    this.update()
  }

  update() {
    const pb    = this.personalBestValue
    const value = parseInt(this.inputTarget.value, 10)

    if (!pb || pb === 0 || !value || isNaN(value)) {
      this.previewTarget.hidden = true
      return
    }

    const pct = Math.round((value / pb) * 100)
    const { zone, label, css } = this.classify(pct)

    this.previewTarget.hidden = false
    this.previewTarget.className = `zone-preview zone-preview--${zone}`
    this.previewTarget.innerHTML =
      `<span class="zone-preview-dot" aria-hidden="true"></span>` +
      `<span class="zone-preview-text">${label} <span class="zone-preview-pct">(${pct}% of your personal best)</span></span>`
    this.previewTarget.setAttribute("aria-label", `${label} — ${pct}% of your personal best`)
  }

  classify(pct) {
    if (pct >= this.constructor.GREEN) {
      return { zone: "green",  label: "Green zone",  css: "green" }
    } else if (pct >= this.constructor.YELLOW) {
      return { zone: "yellow", label: "Yellow zone", css: "yellow" }
    } else {
      return { zone: "red",    label: "Red zone",    css: "red" }
    }
  }
}
