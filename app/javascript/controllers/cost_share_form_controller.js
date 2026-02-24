import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "appliesToField",
    "moduleWrapper",
    "benefitWrapper",
    "moduleField",
    "benefitField",
    "typeField",
    "unitField",
    "perField",
    "amountField",
    "percentAmountWrapper",
    "moneyAmountsWrapper",
    "amountUsdField",
    "amountGbpField",
    "amountEurField",
    "memberCapWrapper",
    "capAmountUsdField",
    "capAmountGbpField",
    "capAmountEurField",
    "capPeriodField",
    "benefitLimitGroupWrapper",
    "ruleTableWrapper",
    "ruleRow",
    "ruleCheckbox"
  ]

  connect() {
    this.syncFromAppliesTo()
    this.syncFromType()
    this.filterRules()
  }

  syncFromModule() {
    this.filterBenefitOptions()
    this.filterRules()
  }

  syncFromBenefit() {
    this.filterRules()
  }

  syncFromAppliesTo() {
    if (!this.hasAppliesToFieldTarget) return

    const appliesTo = this.appliesToFieldTarget.value
    const benefitScope = appliesTo === "module_benefit" || appliesTo === "benefit_limit_rule"

    if (this.hasModuleWrapperTarget) {
      this.moduleWrapperTarget.classList.toggle("hidden", !["plan_module", "module_benefit"].includes(appliesTo))
    }

    if (this.hasBenefitWrapperTarget) {
      this.benefitWrapperTarget.classList.toggle("hidden", !["module_benefit", "benefit_limit_rule"].includes(appliesTo))
    }

    if (this.hasTypeFieldTarget) {
      this.typeFieldTarget.value = benefitScope ? "coinsurance" : "deductible"
    }

    if (this.hasBenefitLimitGroupWrapperTarget) {
      this.benefitLimitGroupWrapperTarget.classList.toggle("hidden", appliesTo !== "benefit_limit_group")
    }

    if (this.hasRuleTableWrapperTarget) {
      this.ruleTableWrapperTarget.classList.toggle("hidden", appliesTo !== "benefit_limit_rule")
    }

    if (appliesTo !== "benefit_limit_rule") {
      this.ruleCheckboxTargets.forEach((checkbox) => {
        checkbox.checked = false
      })
    }

    this.filterBenefitOptions()
    this.filterRules()
    this.syncFromType()
  }

  syncFromType() {
    if (!this.hasTypeFieldTarget) return

    const type = this.typeFieldTarget.value
    const isCoinsurance = type === "coinsurance"
    const isCapEligible = type === "coinsurance" || type === "excess"

    if (this.hasUnitFieldTarget) {
      this.unitFieldTarget.value = isCoinsurance ? "percent" : "amount"
    }

    if (isCoinsurance && this.hasPerFieldTarget) {
      this.perFieldTarget.value = "per_event"
    }

    if (this.hasPercentAmountWrapperTarget) {
      this.percentAmountWrapperTarget.classList.toggle("hidden", !isCoinsurance)
    }

    if (this.hasMoneyAmountsWrapperTarget) {
      this.moneyAmountsWrapperTarget.classList.toggle("hidden", isCoinsurance)
    }

    if (this.hasMemberCapWrapperTarget) {
      this.memberCapWrapperTarget.classList.toggle("hidden", !isCapEligible)
    }

    if (isCoinsurance) {
      if (this.hasAmountUsdFieldTarget) this.amountUsdFieldTarget.value = ""
      if (this.hasAmountGbpFieldTarget) this.amountGbpFieldTarget.value = ""
      if (this.hasAmountEurFieldTarget) this.amountEurFieldTarget.value = ""
    } else if (this.hasAmountFieldTarget) {
      this.amountFieldTarget.value = ""
    }

    if (!isCapEligible) {
      if (this.hasCapAmountUsdFieldTarget) this.capAmountUsdFieldTarget.value = ""
      if (this.hasCapAmountGbpFieldTarget) this.capAmountGbpFieldTarget.value = ""
      if (this.hasCapAmountEurFieldTarget) this.capAmountEurFieldTarget.value = ""
      if (this.hasCapPeriodFieldTarget) this.capPeriodFieldTarget.value = ""
    }
  }

  filterBenefitOptions() {
    return
  }

  filterRules() {
    if (!this.hasRuleRowTarget || !this.hasBenefitFieldTarget) return

    const selectedBenefitId = this.benefitFieldTarget.value

    this.ruleRowTargets.forEach((row) => {
      const ruleBenefitId = row.dataset.moduleBenefitId
      let visible = true

      if (selectedBenefitId) {
        visible = ruleBenefitId === selectedBenefitId
      }

      row.classList.toggle("hidden", !visible)
      if (!visible) {
        const checkbox = row.querySelector("input[type='checkbox']")
        if (checkbox) checkbox.checked = false
      }
    })
  }
}
