import { Controller } from "@hotwired/stimulus"

// Gives feedback while a search is running: the old results disappear and a message shows up,
// and the button says "Searching…" and cannot be pressed twice. A search can take a few seconds (or longer if Render was asleep).
export default class extends Controller {
  start() {
    const button = this.element.querySelector("button[type=submit]")
    this.label = button.textContent
    button.disabled = true
    button.textContent = "Searching…"
    this.#content().hidden = true
    this.#message().hidden = false
  }

  // Coming back with the browser's back button restores the page with the button still disabled.
  reset() {
    const button = this.element.querySelector("button[type=submit]")
    button.disabled = false
    if (this.label) button.textContent = this.label
    this.#content().hidden = false
    this.#message().hidden = true
  }

  #content() { return document.querySelector("[data-loading-content]") || document.createElement("div") }
  #message() { return document.querySelector("[data-loading-message]") || document.createElement("p") }
}
