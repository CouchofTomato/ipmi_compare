require "system_helper"

RSpec.describe "Plan comparison view", type: :system do
  it "renders comparison data grouped by coverage category" do
    user = create(:user, email: "comparison@example.com", password: "password123")
    progress = create(:wizard_progress, :plan_comparison, user: user, current_step: "comparison")

    category = create(:coverage_category, name: "Inpatient #{SecureRandom.hex(4)}", position: 1)
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

    login_as(user, scope: :user)
    visit wizard_progress_path(progress)

    expect(page).to have_text(/inpatient/i)
    expect(page).to have_content("Hospital stay")
    expect(page).to have_content("Covered")
  end

  it "shows empty state when no plans are selected" do
    user = create(:user, email: "empty@example.com", password: "password123")
    progress = create(:wizard_progress, :plan_comparison, user: user, current_step: "comparison", state: {})

    login_as(user, scope: :user)
    visit wizard_progress_path(progress)

    expect(page).to have_content("No plans selected yet")
  end

  it "renders benefit-level rules before itemised rules" do
    user = create(:user, email: "comparison-with-limits@example.com", password: "password123")
    progress = create(:wizard_progress, :plan_comparison, user: user, current_step: "comparison")

    category = create(:coverage_category, name: "Outpatient #{SecureRandom.hex(4)}", position: 1)
    benefit = create(:benefit, name: "Diagnostics", coverage_category: category)

    plan = create(:plan)
    plan_version = plan.current_plan_version
    group = create(:module_group, plan_version: plan_version, name: "Core")
    plan_module = create(:plan_module, plan_version: plan_version, module_group: group, name: "Core module")
    module_benefit = create(:module_benefit, plan_module: plan_module, benefit: benefit, coverage_description: "Covered")
    create(:cost_share, scope: module_benefit, cost_share_type: :coinsurance, amount: 100, unit: :percent, per: :per_year)
    create(:benefit_limit_rule, module_benefit:, scope: :benefit_level, limit_type: :amount, insurer_amount_usd: 50, unit: "per session", cap_insurer_amount_usd: 500, cap_unit: "per policy year", position: 0)
    create(:benefit_limit_rule, module_benefit:, scope: :itemised, name: "MRI scans", limit_type: :amount, insurer_amount_usd: 1200, unit: "per examination", position: 1)

    progress.update!(
      state: {
        "plan_selections" => [
          { "plan_id" => plan.id, "module_groups" => { group.id.to_s => plan_module.id } }
        ]
      }
    )

    login_as(user, scope: :user)
    visit wizard_progress_path(progress)

    expect(page).to have_content("100% coinsurance (per year), USD 50.00 per session, up to USD 500.00 per policy year")
    expect(page).to have_content("MRI scans")
  end

  it "renders as charged rules correctly" do
    user = create(:user, email: "comparison-only-sublimits@example.com", password: "password123")
    progress = create(:wizard_progress, :plan_comparison, user: user, current_step: "comparison")

    category = create(:coverage_category, name: "Outpatient #{SecureRandom.hex(4)}", position: 1)
    benefit = create(:benefit, name: "Diagnostics", coverage_category: category)

    plan = create(:plan)
    plan_version = plan.current_plan_version
    group = create(:module_group, plan_version: plan_version, name: "Core")
    plan_module = create(:plan_module, plan_version: plan_version, module_group: group, name: "Core module")
    module_benefit = create(:module_benefit, plan_module: plan_module, benefit: benefit, coverage_description: "Covered")
    create(:benefit_limit_rule, module_benefit:, scope: :itemised, name: "CT scans", limit_type: :as_charged, cap_insurer_amount_usd: 500, cap_unit: "per policy year", position: 0)

    progress.update!(
      state: {
        "plan_selections" => [
          { "plan_id" => plan.id, "module_groups" => { group.id.to_s => plan_module.id } }
        ]
      }
    )

    login_as(user, scope: :user)
    visit wizard_progress_path(progress)

    expect(page).to have_content("CT scans")
    expect(page).to have_content("As charged, up to USD 500.00 per policy year")
  end

  it "uses rule-level cost share over benefit-level cost share and does not show plan/module deductibles inline" do
    user = create(:user, email: "comparison-rule-precedence@example.com", password: "password123")
    progress = create(:wizard_progress, :plan_comparison, user: user, current_step: "comparison")

    category = create(:coverage_category, name: "Dental #{SecureRandom.hex(4)}", position: 1)
    benefit = create(:benefit, name: "Routine dental treatment", coverage_category: category)

    plan = create(:plan)
    plan_version = plan.current_plan_version
    group = create(:module_group, plan_version: plan_version, name: "Dental")
    plan_module = create(:plan_module, plan_version: plan_version, module_group: group, name: "Dental module")
    create(:cost_share, scope: plan_version, kind: :deductible, cost_share_type: :deductible, amount_usd: 500, unit: :amount, per: :per_year)
    create(:cost_share, scope: plan_module, kind: :deductible, cost_share_type: :deductible, amount_usd: 100, unit: :amount, per: :per_visit)

    module_benefit = create(:module_benefit, plan_module: plan_module, benefit: benefit, coverage_description: "Covered")
    create(:cost_share, scope: module_benefit, kind: :coinsurance, cost_share_type: :coinsurance, amount: 70, unit: :percent, per: :per_visit)

    root_treatment = create(:benefit_limit_rule, module_benefit:, scope: :itemised, name: "Root treatment", limit_type: :amount, insurer_amount_usd: 380, unit: "per tooth", position: 0)
    extraction = create(:benefit_limit_rule, module_benefit:, scope: :itemised, name: "Extraction", limit_type: :amount, insurer_amount_usd: 200, unit: "per tooth", position: 1)
    create(:cost_share, scope: root_treatment, kind: :coinsurance, cost_share_type: :coinsurance, amount: 80, unit: :percent, per: :per_visit)

    progress.update!(
      state: {
        "plan_selections" => [
          { "plan_id" => plan.id, "module_groups" => { group.id.to_s => plan_module.id } }
        ]
      }
    )

    login_as(user, scope: :user)
    visit wizard_progress_path(progress)

    expect(page).to have_content("Root treatment: 80% coinsurance (per visit), USD 380.00 per tooth")
    expect(page).to have_content("Extraction: 70% coinsurance (per visit), USD 200.00 per tooth")
    expect(page).not_to have_content("Deductible")
  end
end
