import { Controller } from "@hotwired/stimulus"

// Live-previews an avatar image before upload.
// On file selection, reads the file with FileReader and swaps in the preview URL,
// showing the <img> element and hiding the initials fallback.
export default class extends Controller {
  static targets = ["image", "initials", "fileInput"]

  preview() {
    const file = this.fileInputTarget.files[0]
    if (!file) return

    const reader = new FileReader()
    reader.onload = (e) => {
      this.imageTarget.src = e.target.result
      this.imageTarget.removeAttribute("hidden")
      if (this.hasInitialsTarget) {
        this.initialsTarget.setAttribute("hidden", "")
      }
    }
    reader.readAsDataURL(file)
  }
}
