import { Controller } from "@hotwired/stimulus"

// Manages a pill-shaped toggle chip list for asthma triggers.
// Creates one hidden <input name="symptom_log[triggers][]"> per selected trigger
// so the standard Rails array params permit (triggers: []) continues to work.
// Works with or without JavaScript: pre-selected chips are marked via aria-pressed="true"
// in the ERB, and initial hidden inputs are rendered server-side for the no-JS case.
export default class extends Controller {
  static targets = ["chip", "container"]

  connect() {
    // Render hidden inputs from the current aria-pressed chip state.
    // This is authoritative over any server-rendered inputs in the container.
    this.#render()
  }

  toggle(event) {
    const chip = event.currentTarget
    const pressed = chip.getAttribute("aria-pressed") === "true"
    chip.setAttribute("aria-pressed", String(!pressed))
    chip.classList.toggle("trigger-chip--selected", !pressed)
    this.#render()
  }

  // Private

  #render() {
    // Remove all current hidden inputs managed by this controller
    this.containerTarget
      .querySelectorAll('input[type="hidden"]')
      .forEach(el => el.remove())

    // Recreate one hidden input per selected chip
    this.chipTargets
      .filter(chip => chip.getAttribute("aria-pressed") === "true")
      .forEach(chip => {
        const input = document.createElement("input")
        input.type  = "hidden"
        input.name  = "symptom_log[triggers][]"
        input.value = chip.dataset.value
        this.containerTarget.appendChild(input)
      })
  }
}
