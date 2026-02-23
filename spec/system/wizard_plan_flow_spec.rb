require "system_helper"

RSpec.describe "Plan wizard", type: :system do
  it "walks through the full plan creation flow with modules, benefits, limits, cost shares, and cost share links" do
    user = create(:user, email: "wizard@example.com", password: "password123", admin: true)
    insurer = create(:insurer, name: "Acme Health")
    coverage_category = create(:coverage_category, name: "Hospitalisation")
    benefit = create(:benefit, name: "Inpatient care", coverage_category: coverage_category)
    area = create(:geographic_cover_area, name: "Europe", code: "EU")

    login_as(user, scope: :user)

    visit wizard_progresses_path(wizard_type: "plan_creation")
    find(:test_id, "start-plan-wizard-button").click

    expect(page).to have_content("Step 1: Plan details")
    find(:test_id, "insurer-select-field").select(insurer.name)
    find(:test_id, "plan-name-field").set("Global Gold")
    find(:test_id, "min-age-field").set(0)
    find(:test_id, "max-age-field").set(65)
    find(:test_id, "version-year-field").set(Date.current.year)
    find(:test_id, "effective-on-field").set(Date.current.strftime("%Y-%m-%d"))
    find(:test_id, "policy-type-field").select "Individual"
    find(:test_id, "next-review-due-field").set(Date.current.next_year.strftime('%Y-%m-%d'))
    find(:test_id, "last-reviewed-at-field").set(Date.current.strftime('%Y-%m-%d'))
    find(:test_id, "review-notes-field").set("System spec created plan.")
    find(:test_id, "next-step-button").click

    expect(page).to have_content("Step 2: Residency eligibility", wait: 10)
    find(:test_id, "next-step-button").click

    expect(page).to have_content("Step 3: Geographic coverage", wait: 10)
    find(:test_id, "area-#{area.id}-checkbox").check
    find(:test_id, "next-step-button").click

    expect(page).to have_content("Step 4: Module groups", wait: 10)
    find(:test_id, "module-group-name-field").set("Core")
    find(:test_id, "module-group-description-field").set("Included for every member.")
    find(:test_id, "add-module-group-button").click
    expect(page).to have_content("Core")
    find(:test_id, "next-step-button").click

    expect(page).to have_content("Step 5: Plan modules", wait: 10)
    find(:test_id, "module-name-field").set("Hospital module")
    find(:test_id, "module-group-field").select "Core"
    find(:test_id, "is-core-checkbox").check
    find(:test_id, "coverage-category-#{coverage_category.id}-checkbox").check
    find(:test_id, "add-module-button").click
    expect(page).to have_content("Hospital module")
    expect(page).to have_content(coverage_category.name)
    find(:test_id, "next-step-button").click

    expect(page).to have_content("Step 6: Module requirements", wait: 10)
    expect(page).to have_content("No other modules to require.")
    find(:test_id, "next-step-button").click

    expect(page).to have_content("Step 7: Module benefits", wait: 10)
    find(:test_id, "module-field").select "Core – Hospital module"
    find(:test_id, "benefit-field").select benefit.name
    find(:test_id, "coverage-description-field").set("Covers inpatient stays and surgery.")
    find(:test_id, "add-benefit-limit-rule-button").click
    first_row = all("[data-benefit-limit-rules-target='row']").first
    within(first_row) do
      find(:test_id, "benefit-limit-rule-name-field").set("MRI scans")
      find(:test_id, "benefit-limit-rule-scope-field").select "Itemised"
      find(:test_id, "benefit-limit-rule-type-field").select "Amount"
      find("input[name*='[insurer_amount_usd]']").set("1200")
      find("input[name$='[unit]']").set("per examination")
    end
    find(:test_id, "add-benefit-limit-rule-button").click
    second_row = all("[data-benefit-limit-rules-target='row']").last
    within(second_row) do
      find(:test_id, "benefit-limit-rule-name-field").set("CT scans")
      find(:test_id, "benefit-limit-rule-scope-field").select "Itemised"
      find(:test_id, "benefit-limit-rule-type-field").select "As charged"
      find("input[name*='[cap_insurer_amount_usd]']").set("2000")
      find("input[name*='[cap_unit]']").set("per policy year")
    end
    find(:test_id, "interaction-type-field").select "Replace"
    find(:test_id, "add-module-benefit-button").click
    expect(page).to have_content(benefit.name)
    expect(page).to have_content("Itemised limits")
    find(:test_id, "edit-module-benefit-#{ModuleBenefit.last.id}-button").click
    expect(page).to have_content("Update module benefit")
    last_row = all("[data-benefit-limit-rules-target='row']").last
    within(last_row) do
      find(:test_id, "remove-benefit-limit-rule-button").click
    end
    find(:test_id, "add-module-benefit-button").click
    expect(page).not_to have_content("CT scans")
    find(:test_id, "next-step-button").click

    expect(page).to have_content("Step 8: Benefit limit groups", wait: 10)
    find(:test_id, "module-field").select "Core – Hospital module"
    find(:test_id, "limit-group-name-field").set("Annual inpatient limit")
    find(:test_id, "limit-usd-field").set(10_000)
    find(:test_id, "limit-unit-field").set("per year")
    find(:test_id, "module-benefits-field").select benefit.name
    find(:test_id, "add-benefit-limit-group-button").click
    expect(page).to have_content("Annual inpatient limit")
    find(:test_id, "next-step-button").click

    expect(page).to have_content("Step 9: Cost shares", wait: 10)
    find(:test_id, "applies-to-field").select "Plan"
    find(:test_id, "cost-share-type-field").select "Deductible"
    find(:test_id, "cost-share-amount-field").set(250)
    find(:test_id, "cost-share-unit-field").select "Amount"
    find(:test_id, "cost-share-per-field").select "Per year"
    find(:test_id, "cost-share-currency-field").set("USD")
    find(:test_id, "add-cost-share-button").click
    expect(page).to have_content("Deductible")

    find(:test_id, "applies-to-field").select "Module"
    find(:test_id, "module-field").select "Core – Hospital module"
    find(:test_id, "cost-share-type-field").select "Coinsurance"
    find(:test_id, "cost-share-amount-field").set(20)
    find(:test_id, "cost-share-unit-field").select "Percent"
    find(:test_id, "cost-share-per-field").select "Per visit"
    find(:test_id, "add-cost-share-button").click
    expect(page).to have_content("Coinsurance")

    find(:test_id, "applies-to-field").select "Benefit limit group"
    find(:test_id, "benefit-limit-group-field").select "Core · Hospital module — Annual inpatient limit"
    find(:test_id, "cost-share-type-field").select "Excess"
    find(:test_id, "cost-share-amount-field").set(100)
    find(:test_id, "cost-share-unit-field").select "Amount"
    find(:test_id, "cost-share-per-field").select "Per condition"
    find(:test_id, "cost-share-currency-field").set("GBP")
    find(:test_id, "add-cost-share-button").click
    expect(page).to have_content("Excess")
    find(:test_id, "next-step-button").click

    expect(page).to have_content("Step 10: Link cost shares", wait: 10)
    find(:test_id, "primary-cost-share-field").select "Plan — Deductible — USD250.00 (Per year)"
    find(:test_id, "linked-cost-share-field").select "Core · Hospital module — Coinsurance — 20.0% (Per visit)"
    find(:test_id, "relationship-type-field").select "Shared pool"
    find(:test_id, "add-cost-share-link-button").click
    expect(page).to have_content("Shared pool")
    expect(page).to have_content("Plan — Deductible — USD250.00 (Per year)")
    expect(page).to have_content("Core · Hospital module — Coinsurance — 20.0% (Per visit)")
    find(:test_id, "next-step-button").click

    expect(page).to have_content("Step 11: Review & publish", wait: 10)
    expect(page).to have_content("Global Gold")
    expect(page).to have_content("Core")
    expect(page).to have_content("Hospital module")
    expect(page).to have_content(benefit.name)
    expect(page).to have_content("Annual inpatient limit")
    expect(page).to have_content("Deductible")
    expect(page).to have_content("Excess")
    expect(page).to have_content("SHARED POOL")

    find(:test_id, "publish-plan-button").click

    expect(page).to have_content("Plan published and wizard completed")
    expect(page).to have_content("Global Gold")
  end
end
