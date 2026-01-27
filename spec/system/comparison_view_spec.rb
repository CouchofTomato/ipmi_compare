require "system_helper"

RSpec.describe "Plan comparison view", type: :system do
  def sign_in(email:, password:)
    visit new_user_session_path
    fill_in "Email", with: email
    fill_in "Password", with: password
    click_button "Log in"
    expect(page).to have_current_path(root_path)
  end

  it "renders comparison data grouped by coverage category" do
    user = create(:user, email: "comparison@example.com", password: "password123")
    progress = create(:wizard_progress, :plan_comparison, user: user, current_step: "comparison")

    category = create(:coverage_category, name: "Inpatient", position: 1)
    benefit = create(:benefit, name: "Hospital stay", coverage_category: category)

    plan = create(:plan)
    plan_version = plan.current_plan_version
    group = create(:module_group, plan_version: plan_version)
    plan_module = create(:plan_module, plan_version: plan_version, module_group: group, name: "Core")

    create(:module_benefit, plan_module: plan_module, benefit: benefit, coverage_description: "Covered")

    progress.update!(
      state: {
        "plan_selections" => [
          { "plan_id" => plan.id, "module_groups" => { group.id.to_s => plan_module.id } }
        ]
      }
    )

    sign_in(email: user.email, password: "password123")
    visit wizard_progress_path(progress)

    expect(page).to have_text(/inpatient/i)
    expect(page).to have_content("Hospital stay")
    expect(page).to have_content("Covered")
  end

  it "shows empty state when no plans are selected" do
    user = create(:user, email: "empty@example.com", password: "password123")
    progress = create(:wizard_progress, :plan_comparison, user: user, current_step: "comparison", state: {})

    sign_in(email: user.email, password: "password123")
    visit wizard_progress_path(progress)

    expect(page).to have_content("No plans selected yet")
  end
end
