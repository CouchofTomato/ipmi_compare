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
    click_button "Start plan wizard"

    select insurer.name, from: "Insurer"
    fill_in "Plan name", with: "Global Gold"
    fill_in "Min age", with: 0
    fill_in "Max age", with: 65
    fill_in "Version year", with: Date.current.year
    select "Individual", from: "Policy type"
    fill_in "Next review due", with: Date.current.next_year
    fill_in "Last reviewed at", with: Date.current
    fill_in "Review notes", with: "System spec created plan."
    click_button "Save and continue →"

    expect(page).to have_content("Step 2: Residency eligibility")
    click_button "Save and continue →"

    expect(page).to have_content("Step 3: Geographic coverage")
    check area.name
    click_button "Save and continue →"

    expect(page).to have_content("Step 4: Module groups")
    fill_in "Module group name", with: "Core"
    fill_in "Description", with: "Included for every member."
    click_button "Add module group"
    expect(page).to have_content("Core")
    click_button "Save and continue →"

    expect(page).to have_content("Step 5: Plan modules")
    fill_in "Module name", with: "Hospital module"
    select "Core", from: "Module group"
    check "Core module"
    click_button "Add module"
    expect(page).to have_content("Hospital module")
    click_button "Save and continue →"

    expect(page).to have_content("Step 6: Module benefits")
    select "Core – Hospital module", from: "Module"
    select coverage_category.name, from: "Coverage category"
    select benefit.name, from: "Benefit"
    fill_in "Coverage description", with: "Covers inpatient stays and surgery."
    select "Replace", from: "Interaction type"
    click_button "Add module benefit"
    expect(page).to have_content(benefit.name)
    click_button "Save and continue →"

    expect(page).to have_content("Step 7: Benefit limit groups")
    select "Core – Hospital module", from: "Module"
    fill_in "Limit group name", with: "Annual inpatient limit"
    fill_in "Limit (USD)", with: 10_000
    fill_in "Limit unit", with: "per year"
    select benefit.name, from: "Module benefits using this limit"
    click_button "Add benefit limit group"
    expect(page).to have_content("Annual inpatient limit")
    click_button "Save and continue →"

    expect(page).to have_content("Step 8: Cost shares")
    select "Plan", from: "Applies to"
    select "Deductible", from: "Type"
    fill_in "Amount", with: 250
    select "Amount", from: "Unit"
    select "Per year", from: "Per"
    fill_in "Currency", with: "USD"
    click_button "Add cost share"
    expect(page).to have_content("Deductible")
    click_button "Save and continue →"

    expect(page).to have_content("Step 9: Review & publish")
    expect(page).to have_content("Global Gold")
    expect(page).to have_content("Core")
    expect(page).to have_content("Hospital module")
    expect(page).to have_content(benefit.name)
    expect(page).to have_content("Annual inpatient limit")
    expect(page).to have_content("Deductible")

    click_button "Finish and publish"

    expect(page).to have_content("Plan published and wizard completed")
    expect(page).to have_content("Global Gold")
    expect(page).to have_content("Published")
  end
end
