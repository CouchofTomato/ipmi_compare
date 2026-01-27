require "system_helper"

RSpec.describe "Plan comparison flow", type: :system do
  def sign_in(email:, password:)
    visit new_user_session_path
    fill_in "Email", with: email
    fill_in "Password", with: password
    click_button "Log in"
    expect(page).to have_current_path(root_path)
  end

  it "adds a plan selection and renders it in the comparison grid" do
    user = create(:user, email: "compare-flow@example.com", password: "password123")

    plan = create(:plan, name: "Acme Gold")
    plan_version = plan.current_plan_version
    group = create(:module_group, plan_version: plan_version, name: "Core")
    plan_module = create(:plan_module, plan_version: plan_version, module_group: group, name: "Hospital Plan")

    category = create(:coverage_category, name: "Inpatient", position: 1)
    benefit = create(:benefit, name: "Hospital stay", coverage_category: category)
    create(:module_benefit, plan_module: plan_module, benefit: benefit, coverage_description: "Paid in full")

    progress = create(:wizard_progress, :plan_comparison, user: user, current_step: "plan_selection")

    sign_in(email: user.email, password: "password123")
    visit wizard_progress_path(progress)

    fill_in "Search for a plan", with: "Acme"
    click_button "Search"
    expect(page).to have_content("Acme Gold", wait: 10)

    choose "Hospital Plan"
    click_button "Add to Comparison"

    expect(page).to have_content("Acme Gold", wait: 10)
    click_button "Continue to comparison →"

    expect(page).to have_content("Comparison", wait: 10)
    expect(page).to have_text(/inpatient/i)
    expect(page).to have_content("Hospital stay")
    expect(page).to have_content("Paid in full")
  end

  it "removes a plan from the comparison" do
    user = create(:user, email: "compare-remove@example.com", password: "password123")
    plan = create(:plan, name: "Remove Me")
    plan_version = plan.current_plan_version
    group = create(:module_group, plan_version: plan_version, name: "Core")
    plan_module = create(:plan_module, plan_version: plan_version, module_group: group, name: "Hospital Plan")
    category = create(:coverage_category, name: "Inpatient", position: 1)
    benefit = create(:benefit, name: "Hospital stay", coverage_category: category)
    create(:module_benefit, plan_module: plan_module, benefit: benefit, coverage_description: "Covered")

    progress = create(
      :wizard_progress,
      :plan_comparison,
      user: user,
      current_step: "comparison",
      state: {
        "plan_selections" => [
          { "id" => "sel-1", "plan_id" => plan.id, "module_groups" => { group.id.to_s => plan_module.id } }
        ]
      }
    )

    sign_in(email: user.email, password: "password123")
    visit wizard_progress_path(progress)

    expect(page).to have_content("Remove Me")
    within(:xpath, "//div[contains(@class,'rounded-full')][.//span[contains(.,'Remove Me')]]") do
      click_button "Remove"
    end

    expect(page).to have_content("No plans selected yet", wait: 10)
  end

  it "shows separate columns for the same plan with different module selections" do
    user = create(:user, email: "compare-dupe@example.com", password: "password123")
    plan = create(:plan, name: "Dual Plan")
    plan_version = plan.current_plan_version
    group = create(:module_group, plan_version: plan_version, name: "Core")
    module_a = create(:plan_module, plan_version: plan_version, module_group: group, name: "Module A")
    module_b = create(:plan_module, plan_version: plan_version, module_group: group, name: "Module B")

    category = create(:coverage_category, name: "Outpatient", position: 1)
    benefit = create(:benefit, name: "Consultations", coverage_category: category)
    create(:module_benefit, plan_module: module_a, benefit: benefit, coverage_description: "A coverage")
    create(:module_benefit, plan_module: module_b, benefit: benefit, coverage_description: "B coverage")

    progress = create(
      :wizard_progress,
      :plan_comparison,
      user: user,
      current_step: "comparison",
      state: {
        "plan_selections" => [
          { "id" => "sel-a", "plan_id" => plan.id, "module_groups" => { group.id.to_s => module_a.id } },
          { "id" => "sel-b", "plan_id" => plan.id, "module_groups" => { group.id.to_s => module_b.id } }
        ]
      }
    )

    sign_in(email: user.email, password: "password123")
    visit wizard_progress_path(progress)

    expect(page).to have_content("Dual Plan")
    expect(page).to have_text(/outpatient/i)
    expect(page).to have_content("Consultations")
    expect(page).to have_content("A coverage")
    expect(page).to have_content("B coverage")
  end
end
