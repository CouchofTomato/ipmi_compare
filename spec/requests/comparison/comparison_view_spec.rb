require "rails_helper"

RSpec.describe "Plan comparison view", type: :request do
  let(:user) { create(:user) }
  let(:progress) { create(:wizard_progress, :plan_comparison, user: user, current_step: "comparison") }

  before do
    sign_in user
  end

  it "renders comparison data grouped by coverage category" do
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

    get wizard_progress_path(progress)

    expect(response).to have_http_status(:success)
    expect(response.body).to include("Inpatient")
    expect(response.body).to include("Hospital stay")
    expect(response.body).to include("Covered")
  end

  it "shows empty state when no plans are selected" do
    progress.update!(state: {})

    get wizard_progress_path(progress)

    expect(response).to have_http_status(:success)
    expect(response.body).to include("No plans selected yet")
  end
end
