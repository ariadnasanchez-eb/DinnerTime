import { Controller } from "@hotwired/stimulus"

// Hides an image that fails to load, so the browser does not show a broken-image icon.
// Many dataset photos no longer exist; the card then shows its placeholder instead.
export default class extends Controller {
  connect() {
    // The error may have happened before this controller started listening.
    if (this.element.complete && this.element.naturalWidth === 0) this.hide()
  }

  hide() {
    this.element.classList.add("broken")
  }
}
