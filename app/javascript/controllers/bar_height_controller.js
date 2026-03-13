import { Controller } from "@hotwired/stimulus"

// Sets --bar-fill-height CSS custom property from a data attribute so the
// value never appears as an inline style attribute (which violates style-src-attr CSP).
export default class extends Controller {
  connect() {
    this.element.style.setProperty("--bar-fill-height", this.element.dataset.barHeightValue)
  }
}
