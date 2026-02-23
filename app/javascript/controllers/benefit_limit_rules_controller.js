import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "template", "row", "limitType", "amountFields", "unitField", "capFields", "destroyField"]

  connect() {
    this.syncAllRows()
  }

  addRow() {
    if (!this.hasTemplateTarget || !this.hasContainerTarget) return

    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, String(Date.now()))
    this.containerTarget.insertAdjacentHTML("beforeend", content)
    this.syncAllRows()
  }

  removeRow(event) {
    const row = event.currentTarget.closest('[data-benefit-limit-rules-target="row"]')
    if (!row) return

    const destroyField = row.querySelector('[data-benefit-limit-rules-target="destroyField"]')

    if (row.dataset.newRecord === "true") {
      row.remove()
      return
    }

    if (destroyField) {
      destroyField.value = "1"
    }

    row.classList.add("hidden")
  }

  toggleLimitType(event) {
    const row = event.currentTarget.closest('[data-benefit-limit-rules-target="row"]')
    if (!row) return

    this.syncRow(row)
  }

  syncAllRows() {
    this.rowTargets.forEach((row) => this.syncRow(row))
  }

  syncRow(row) {
    const limitTypeSelect = row.querySelector('[data-benefit-limit-rules-target="limitType"]')
    if (!limitTypeSelect) return

    const amountFields = row.querySelector('[data-benefit-limit-rules-target="amountFields"]')
    const unitField = row.querySelector('[data-benefit-limit-rules-target="unitField"]')
    const capFields = row.querySelector('[data-benefit-limit-rules-target="capFields"]')
    const amountFieldInputs = row.querySelectorAll("input[name*='[insurer_amount_']")
    const unitInput = row.querySelector("input[name$='[unit]']")
    const capInputs = row.querySelectorAll("input[name*='[cap_insurer_amount_'], input[name*='[cap_unit]']")
    const limitType = limitTypeSelect.value

    if (amountFields) {
      amountFields.classList.toggle("hidden", limitType !== "amount")
    }

    if (unitField) {
      unitField.classList.toggle("hidden", limitType !== "amount")
    }

    if (capFields) {
      capFields.classList.toggle("hidden", limitType === "not_stated")
    }

    amountFieldInputs.forEach((input) => {
      input.disabled = limitType !== "amount"
    })

    if (unitInput) {
      unitInput.disabled = limitType !== "amount"
    }

    capInputs.forEach((input) => {
      input.disabled = limitType === "not_stated"
    })
  }
}
