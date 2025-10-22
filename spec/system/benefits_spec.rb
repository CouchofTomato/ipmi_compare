require "system_helper"

RSpec.describe "Benefits", type: :system do
  it "allows creating a benefit" do
    visit benefits_path
    click_link "Add benefit"

    fill_in "Name", with: "Ambulatory care"
    select "Outpatient", from: "Category"
    fill_in "Description", with: "Covers day surgery and outpatient visits."

    click_button "Create benefit"

    expect(page).to have_content("Benefit was successfully created.")
    expect(page).to have_content("Ambulatory care")
    expect(page).to have_content("Outpatient")
    expect(page).to have_content("Covers day surgery and outpatient visits.")
  end

  it "allows updating a benefit" do
    benefit = create(:benefit, name: "Dental cover", category: :dental, description: "Basic dental services.")

    visit benefit_path(benefit)
    click_link "Edit"

    fill_in "Name", with: "Enhanced Dental Cover"
    select "Wellness", from: "Category"
    fill_in "Description", with: "Includes preventative dental checkups."

    click_button "Update benefit"

    expect(page).to have_content("Benefit was successfully updated.")
    expect(page).to have_content("Enhanced Dental Cover")
    expect(page).to have_content("Wellness")
    expect(page).to have_content("Includes preventative dental checkups.")
  end

  it "allows deleting a benefit" do
    benefit = create(:benefit, name: "Legacy plan benefit", category: :inpatient)

    visit benefit_path(benefit)

    accept_confirm do
      click_button "Delete"
    end

    expect(page).to have_current_path(benefits_path)
    expect(page).to have_content("Benefit was successfully deleted.")
    expect(page).not_to have_content("Legacy plan benefit")
  end
end
