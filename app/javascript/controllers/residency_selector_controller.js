import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "region",
    "regionCheckbox",
    "countryList",
    "countryCheckbox",
    "toggleButton"
  ]

  connect() {
    this.regionTargets.forEach((regionElement) => {
      this.updateRegionCheckboxState(regionElement)
    })

    this.toggleButtonTargets.forEach((button) => {
      this.syncToggleButtonState(button)
    })
  }

  toggleCountries(event) {
    const button = event.currentTarget
    const regionElement = this.regionByKey(button.dataset.region)
    if (!regionElement) return

    const countryList = this.countryListForRegion(regionElement)
    if (!countryList) return

    const isHidden = countryList.classList.toggle("hidden")
    this.setToggleButtonState(button, !isHidden)
  }

  toggleRegion(event) {
    const checkbox = event.currentTarget
    const regionElement = this.regionByKey(checkbox.dataset.region)
    if (!regionElement) return

    const countryCheckboxes = this.countryCheckboxes(regionElement)
    const checked = checkbox.checked && !checkbox.indeterminate

    countryCheckboxes.forEach((countryCheckbox) => {
      countryCheckbox.checked = checked
    })

    this.updateRegionCheckboxState(regionElement)
  }

  syncRegion(event) {
    const regionElement = this.regionByKey(event.currentTarget.dataset.region)
    if (!regionElement) return

    this.updateRegionCheckboxState(regionElement)
  }

  updateRegionCheckboxState(regionElement) {
    const regionCheckbox = this.regionCheckboxForRegion(regionElement)
    if (!regionCheckbox) return

    const countryCheckboxes = this.countryCheckboxes(regionElement)
    const checkedCount = countryCheckboxes.filter((checkbox) => checkbox.checked).length

    if (countryCheckboxes.length === 0) {
      regionCheckbox.checked = false
      regionCheckbox.indeterminate = false
      return
    }

    if (checkedCount === 0) {
      regionCheckbox.checked = false
      regionCheckbox.indeterminate = false
    } else if (checkedCount === countryCheckboxes.length) {
      regionCheckbox.checked = true
      regionCheckbox.indeterminate = false
    } else {
      regionCheckbox.checked = true
      regionCheckbox.indeterminate = true
    }
  }

  syncToggleButtonState(button) {
    const regionElement = this.regionByKey(button.dataset.region)
    if (!regionElement) return

    const countryList = this.countryListForRegion(regionElement)
    if (!countryList) return

    this.setToggleButtonState(button, !countryList.classList.contains("hidden"))
  }

  setToggleButtonState(button, expanded) {
    button.setAttribute("aria-expanded", String(expanded))
    const expandIcon = button.querySelector('[data-role="expand-icon"]')
    const collapseIcon = button.querySelector('[data-role="collapse-icon"]')

    if (expandIcon) {
      expandIcon.classList.toggle("hidden", expanded)
    }

    if (collapseIcon) {
      collapseIcon.classList.toggle("hidden", !expanded)
    }

    const srText = button.querySelector(".sr-only")
    if (srText) {
      srText.textContent = expanded ? "Hide countries" : "Show countries"
    }
  }

  regionByKey(regionKey) {
    return this.regionTargets.find((element) => element.dataset.region === regionKey)
  }

  countryListForRegion(regionElement) {
    return regionElement.querySelector('[data-residency-selector-target="countryList"]')
  }

  regionCheckboxForRegion(regionElement) {
    return regionElement.querySelector('[data-residency-selector-target="regionCheckbox"]')
  }

  countryCheckboxes(regionElement) {
    return Array.from(
      regionElement.querySelectorAll(
        '[data-residency-selector-target="countryCheckbox"][data-region="' +
          regionElement.dataset.region +
          '"]'
      )
    )
  }
}
