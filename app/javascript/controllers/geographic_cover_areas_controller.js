import { Controller } from "@hotwired/stimulus"

// Updates the displayed count of selected geographic cover areas.
export default class extends Controller {
  static targets = ["checkbox", "count", "label"]

  connect() {
    this.update()
  }

  update() {
    const selected = this.hasCheckboxTarget
      ? this.checkboxTargets.filter((element) => element.checked).length
      : 0

    if (this.hasCountTarget) {
      this.countTarget.textContent = selected
    }

    if (this.hasLabelTarget) {
      this.labelTarget.textContent = selected === 1 ? "area" : "areas"
    }
  }
}
