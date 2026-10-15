import { Controller } from "@hotwired/stimulus"

// Turns the ingredients text field into a list of "chips" (tags).
//
// - Enter, comma or the + button adds what is typed as a chip. Repeated ingredients are ignored.
//   (On a phone there is no obvious Enter, hence the + button.)
// - The × on a chip removes it. Backspace on an empty field removes the last one.
// - "Clear all" removes every chip (it only shows while there is at least one).
// - Enter on an empty field, with chips already added, sends the search.
// - The chips travel in a hidden field as "egg,tomato", the same format the plain field
//   uses without JavaScript, so the server does not need to know about chips.
export default class extends Controller {
  static targets = [ "input", "list", "clear" ]

  connect() {
    // Start from whatever the server put in the field (a search coming back from the URL).
    this.items = []
    this.#addAll(this.inputTarget.value)
    this.inputTarget.value = ""

    // The visible field now only edits the next chip; the hidden one is what gets submitted.
    this.inputTarget.removeAttribute("name")
    this.hidden = document.createElement("input")
    this.hidden.type = "hidden"
    this.hidden.name = "ingredients"
    this.element.appendChild(this.hidden)

    // If the user presses "Find recipes" with text still in the field, count it too.
    this.element.closest("form").addEventListener("submit", () => this.#addAll(this.inputTarget.value, true))

    this.element.classList.add("chips-ready") // shows the + button, which needs JavaScript
    this.#render()
  }

  keydown(event) {
    if (event.key === "Enter") {
      // Typing something: Enter only adds a chip. With an empty field it sends the search.
      if (this.inputTarget.value.trim() === "" && this.items.length > 0) return

      event.preventDefault()
      this.#addAll(this.inputTarget.value, true)
    } else if (event.key === "Backspace" && this.inputTarget.value === "") {
      this.items.pop()
      this.#render()
    }
  }

  // Typing or pasting a comma ("egg, tomato") closes the chips before it.
  input() {
    const text = this.inputTarget.value
    if (!text.includes(",")) return

    const parts = text.split(",")
    const rest = parts.pop() // what comes after the last comma is still being typed
    this.#addAll(parts.join(","))
    this.inputTarget.value = rest.trimStart()
  }

  // The + button.
  add() {
    this.#addAll(this.inputTarget.value, true)
    this.inputTarget.focus()
  }

  // The "Clear all" button.
  clear() {
    this.items = []
    this.#render()
    this.inputTarget.focus()
  }

  remove(event) {
    this.items.splice(Number(event.params.index), 1)
    this.#render()
    this.inputTarget.focus()
  }

  // Adds every comma-separated name in `text`, skipping blanks and repeats (ignoring case).
  #addAll(text, clear = false) {
    text.split(",").map((name) => name.trim()).filter(Boolean).forEach((name) => {
      if (!this.items.some((item) => item.toLowerCase() === name.toLowerCase())) this.items.push(name)
    })
    if (clear) this.inputTarget.value = ""
    if (this.hidden) this.#render()
  }

  #render() {
    this.hidden.value = this.items.join(",")
    this.clearTarget.hidden = this.items.length === 0
    this.listTarget.replaceChildren(...this.items.map((name, index) => this.#chip(name, index)))
  }

  // Built with textContent (not innerHTML), so what the user types is never run as HTML.
  #chip(name, index) {
    const chip = document.createElement("li")
    chip.className = "chip"
    chip.append(name)

    const button = document.createElement("button")
    button.type = "button"
    button.textContent = "×"
    button.setAttribute("aria-label", `Remove ${name}`)
    button.dataset.action = "chips#remove"
    button.dataset.chipsIndexParam = index
    chip.append(button)

    return chip
  }
}
