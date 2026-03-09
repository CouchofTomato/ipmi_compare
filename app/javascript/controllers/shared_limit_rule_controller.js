import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "ruleType",
    "periodKind",
    "quantityUnitKind",
    "amountFields",
    "usageFields",
    "periodValueField",
    "quantityUnitCustomField"
  ]

  connect() {
    this.sync()
  }

  sync() {
    const ruleType = this.hasRuleTypeTarget ? this.ruleTypeTarget.value : null
    const periodKind = this.hasPeriodKindTarget ? this.periodKindTarget.value : null
    const quantityUnitKind = this.hasQuantityUnitKindTarget ? this.quantityUnitKindTarget.value : null

    const showAmountFields = ruleType === "amount"
    const showUsageFields = ruleType === "usage"
    const showPeriodValue = periodKind === "rolling_days" || periodKind === "rolling_months"
    const showCustomQuantityUnit = showUsageFields && quantityUnitKind === "other"

    if (this.hasAmountFieldsTarget) {
      this.toggleFieldGroup(this.amountFieldsTarget, showAmountFields)
    }

    if (this.hasUsageFieldsTarget) {
      this.toggleFieldGroup(this.usageFieldsTarget, showUsageFields)
    }

    if (this.hasPeriodValueFieldTarget) {
      this.toggleFieldGroup(this.periodValueFieldTarget, showPeriodValue)
    }

    if (this.hasQuantityUnitCustomFieldTarget) {
      this.toggleFieldGroup(this.quantityUnitCustomFieldTarget, showCustomQuantityUnit)
    }
  }

  toggleFieldGroup(element, visible) {
    element.classList.toggle("hidden", !visible)

    element.querySelectorAll("input, select, textarea").forEach((input) => {
      input.disabled = !visible
    })
  }
}
