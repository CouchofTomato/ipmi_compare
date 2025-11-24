require "system_helper"

RSpec.describe "Plan wizard", type: :system do
  def sign_in(email:, password:)
    visit new_user_session_path
    fill_in "Email", with: email
    fill_in "Password", with: password
    click_button "Log in"
    expect(page).to have_current_path(root_path)
  end

  it "walks through the full plan creation flow with modules, benefits, limits, and cost shares" do
    user = create(:user, email: "wizard@example.com", password: "password123")
    insurer = create(:insurer, name: "Acme Health")
    coverage_category = create(:coverage_category, name: "Hospitalization")
    benefit = create(:benefit, name: "Inpatient care")
    area = create(:geographic_cover_area, name: "Europe", code: "EU")

    sign_in(email: user.email, password: "password123")

    visit wizard_progresses_path
    find(:test_id, "start-plan-wizard-button").click

    expect(page).to have_content("Step 1: Plan details")
    find(:test_id, "insurer-select-field").select(insurer.name)
    find(:test_id, "plan-name-field").fill_in with: "Global Gold"
    find(:test_id, "min-age-field").fill_in with: 0
    find(:test_id, "max-age-field").fill_in with: 65
    find(:test_id, "version-year-field").fill_in with: Date.current.year
    find(:test_id, "policy-type-field").select "Individual"
    find(:test_id, "next-review-due-field").fill_in with: Date.current.next_year
    find(:test_id, "last-reviewed-at-field").fill_in with: Date.current
    find(:test_id, "review-notes-field").fill_in with: "System spec created plan."
    find(:test_id, "next-step-button").click

    expect(page).to have_content("Step 2: Residency eligibility")
    find(:test_id, "next-step-button").click

    expect(page).to have_content("Step 3: Geographic coverage")
    find(:test_id, "area-#{area.id}-checkbox").check
    find(:test_id, "next-step-button").click

    expect(page).to have_content("Step 4: Module groups")
    find(:test_id, "module-group-name-field").fill_in with: "Core"
    find(:test_id, "module-group-description-field").fill_in with: "Included for every member."
    find(:test_id, "add-module-group-button").click
    expect(page).to have_content("Core")
    find(:test_id, "next-step-button").click

    expect(page).to have_content("Step 5: Plan modules")
    find(:test_id, "module-name-field").fill_in with: "Hospital module"
    find(:test_id, "module-group-field").select "Core"
    find(:test_id, "is-core-checkbox").check
    find(:test_id, "add-module-button").click
    expect(page).to have_content("Hospital module")
    find(:test_id, "next-step-button").click

    expect(page).to have_content("Step 6: Module benefits")
    find(:test_id, "module-field").select "Core – Hospital module"
    find(:test_id, "coverage-category-field").select coverage_category.name
    find(:test_id, "benefit-field").select benefit.name
    find(:test_id, "coverage-description-field").fill_in with: "Covers inpatient stays and surgery."
    find(:test_id, "interaction-type-field").select "Replace"
    find(:test_id, "add-module-benefit-button").click
    expect(page).to have_content(benefit.name)
    find(:test_id, "next-step-button").click

    expect(page).to have_content("Step 7: Benefit limit groups")
    find(:test_id, "module-field").select "Core – Hospital module"
    find(:test_id, "limit-group-name-field").fill_in with: "Annual inpatient limit"
    find(:test_id, "limit-usd-field").fill_in with: 10_000
    find(:test_id, "limit-unit-field").fill_in with: "per year"
    find(:test_id, "module-benefits-field").select benefit.name
    find(:test_id, "add-benefit-limit-group-button").click
    expect(page).to have_content("Annual inpatient limit")
    find(:test_id, "next-step-button").click

    expect(page).to have_content("Step 8: Cost shares")
    find(:test_id, "applies-to-field").select "Plan"
    find(:test_id, "cost-share-type-field").select "Deductible"
    find(:test_id, "cost-share-amount-field").fill_in with: 250
    find(:test_id, "cost-share-unit-field").select "Amount"
    find(:test_id, "cost-share-per-field").select "Per year"
    find(:test_id, "cost-share-currency-field").fill_in with: "USD"
    find(:test_id, "add-cost-share-button").click
    expect(page).to have_content("Deductible")
    find(:test_id, "next-step-button").click

    expect(page).to have_content("Step 9: Review & publish")
    expect(page).to have_content("Global Gold")
    expect(page).to have_content("Core")
    expect(page).to have_content("Hospital module")
    expect(page).to have_content(benefit.name)
    expect(page).to have_content("Annual inpatient limit")
    expect(page).to have_content("Deductible")

    find(:test_id, "publish-plan-button").click

    expect(page).to have_content("Plan published and wizard completed")
    expect(page).to have_content("Global Gold")
  end
end
