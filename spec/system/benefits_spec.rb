require "system_helper"

RSpec.describe "Benefits", type: :system do
  def sign_in(email:, password:)
    visit new_user_session_path
    fill_in "Email", with: email
    fill_in "Password", with: password
    click_button "Log in"
    expect(page).to have_current_path(root_path)
  end

  before do
    admin = create(:user, email: "admin@example.com", password: "password123", admin: true)
    sign_in(email: admin.email, password: "password123")
  end

  it "allows creating a benefit" do
    coverage_category = create(:coverage_category, name: "Inpatient")

    visit benefits_path
    click_link "Add benefit"

    fill_in "Name", with: "Ambulatory care"
    fill_in "Description", with: "Covers day surgery and outpatient visits."
    select coverage_category.name, from: "Coverage category"

    click_button "Create benefit"

    expect(page).to have_content("Benefit was successfully created.")
    expect(page).to have_content("Ambulatory care")
    expect(page).to have_content("Covers day surgery and outpatient visits.")
  end

  it "allows updating a benefit" do
    benefit = create(:benefit, name: "Dental cover", description: "Basic dental services.")

    visit benefit_path(benefit)
    click_link "Edit"

    fill_in "Name", with: "Enhanced Dental Cover"
    fill_in "Description", with: "Includes preventative dental checkups."

    click_button "Update benefit"

    expect(page).to have_content("Benefit was successfully updated.")
    expect(page).to have_content("Enhanced Dental Cover")
    expect(page).to have_content("Includes preventative dental checkups.")
  end

  it "allows deleting a benefit" do
    benefit = create(:benefit, name: "Legacy plan benefit")

    visit benefit_path(benefit)

    accept_confirm do
      click_button "Delete"
    end

    expect(page).to have_current_path(benefits_path)
    expect(page).to have_content("Benefit was successfully deleted.")
    expect(page).not_to have_content("Legacy plan benefit")
  end
end
