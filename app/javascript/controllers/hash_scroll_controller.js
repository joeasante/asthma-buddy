import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (window.location.hash.slice(1) === this.element.id) {
      this.element.scrollIntoView()
    }
  }
}
