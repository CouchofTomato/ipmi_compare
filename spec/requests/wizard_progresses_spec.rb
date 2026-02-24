require "rails_helper"

RSpec.describe "WizardProgresses", type: :request do
  let(:admin_user) { create(:user, admin: true) }
  let(:wizard_progress) do
    create(
      :wizard_progress,
      wizard_type: "plan_creation",
      current_step: "plan_residency",
      user: admin_user
    )
  end

  before do
    sign_in admin_user
  end

  describe "GET /show" do
    it "returns http success" do
      get wizard_progress_path(wizard_progress)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /create" do
    it "starts a plan wizard for an existing plan" do
      plan = create(:plan)

      expect do
        post wizard_progresses_path,
             params: { plan_id: plan.id, wizard_type: "plan_creation" }
      end.to change { WizardProgress.where(subject: plan).count }
        .from(0).to(1)

      progress = WizardProgress.find_by(subject: plan)
      expect(progress).to be_present
      expect(progress.current_step).to eq(progress.steps.first)
      expect(progress).to be_in_progress
      expect(progress.metadata["plan_version_id"]).to be_nil
      expect(response).to redirect_to(wizard_progress_path(progress))
    end

    it "resets an existing wizard back to the first step when restarting an edit" do
      plan = create(:plan)
      progress = create(:wizard_progress,
                        wizard_type: "plan_creation",
                        subject: plan,
                        user: wizard_progress.user,
                        current_step: "review",
                        step_order: 9,
                        status: :complete)

      post wizard_progresses_path,
           params: { plan_id: plan.id, wizard_type: "plan_creation" }

      progress.reload
      expect(progress.current_step).to eq(progress.steps.first)
      expect(progress).to be_in_progress
      expect(progress.step_order).to eq(0)
      expect(progress.metadata["plan_version_id"]).to be_nil
    end

    it "creates a separate wizard for another user editing the same plan" do
      plan = create(:plan)
      other_user = create(:user, email: "other_user@example.com")
      original = create(:wizard_progress,
                        wizard_type: "plan_creation",
                        subject: plan,
                        user: other_user,
                        current_step: "review",
                        step_order: 9)

      expect do
        post wizard_progresses_path,
             params: { plan_id: plan.id, wizard_type: "plan_creation" }
      end.to change { WizardProgress.where(subject: plan).count }.by(1)

      new_progress = WizardProgress.where(subject: plan, user: wizard_progress.user).last
      expect(new_progress).to be_present
      expect(new_progress).not_to eq(original)
      expect(new_progress.current_step).to eq(new_progress.steps.first)
    end

    it "creates a new draft plan version when requested" do
      plan = create(:plan)

      expect do
        post wizard_progresses_path,
             params: { plan_id: plan.id, wizard_type: "plan_creation", new_version: true }
      end.to change { plan.plan_versions.reload.count }.by(1)

      progress = WizardProgress.find_by(subject: plan, user: wizard_progress.user)
      expect(progress.metadata["plan_version_id"]).to be_present
      draft_version = plan.plan_versions.find(progress.metadata["plan_version_id"])
      expect(draft_version).not_to eq(plan.current_plan_version)
      expect(draft_version).not_to be_current
    end
  end

  describe "PATCH /update" do
    it "returns http success for turbo stream submissions" do
      expect do
        patch wizard_progress_path(wizard_progress, format: :turbo_stream),
              params: { step_action: "next" }
      end.to change { wizard_progress.reload.current_step }
        .from("plan_residency").to("geographic_cover_areas")

      expect(response).to have_http_status(:success)
    end

    it "targets the plan version stored in metadata when editing" do
      plan = wizard_progress.subject
      draft_version = PlanVersionDuplicator.call(plan.current_plan_version)
      current_group = create(:module_group, plan_version: plan.current_plan_version)
      draft_group = create(:module_group, plan_version: draft_version)

      wizard_progress.update!(
        current_step: "module_groups",
        step_order: 3,
        status: :in_progress,
        metadata: wizard_progress.metadata.merge("plan_version_id" => draft_version.id)
      )

      expect do
        patch wizard_progress_path(wizard_progress, format: :turbo_stream),
              params: { step_action: "delete", module_groups: { id: draft_group.id } }
      end.to change { ModuleGroup.where(id: draft_group.id).count }.by(-1)

      expect(ModuleGroup.where(id: current_group.id)).to exist
    end

    it "deletes a module group that has no modules" do
      plan = wizard_progress.subject
      plan_version = plan.current_plan_version
      module_group = create(:module_group, plan_version:)
      wizard_progress.update!(current_step: "module_groups", step_order: 3, status: :in_progress)
      progress = wizard_progress

      expect do
        patch wizard_progress_path(progress, format: :turbo_stream),
              params: { step_action: "delete", module_groups: { id: module_group.id } }
      end.to change { plan.module_groups.reload.count }.by(-1)

      expect(response).to have_http_status(:success)
    end

    it "deletes a module group and cascades plan modules" do
      plan = wizard_progress.subject
      plan_version = plan.current_plan_version
      module_group = create(:module_group, plan_version:)
      plan_module = create(:plan_module, plan_version:, module_group:)
      wizard_progress.update!(current_step: "module_groups", step_order: 3, status: :in_progress)
      progress = wizard_progress

      expect do
        patch wizard_progress_path(progress, format: :turbo_stream),
              params: { step_action: "delete", module_groups: { id: module_group.id } }
      end.to change { plan.module_groups.reload.count }.by(-1)
        .and change { PlanModule.where(id: plan_module.id).count }.by(-1)

      expect(response).to have_http_status(:success)
    end

    it "deletes a plan module and cascades related objects" do
      plan = wizard_progress.subject
      plan_version = plan.current_plan_version
      module_group = create(:module_group, plan_version:)
      plan_module = create(:plan_module, plan_version:, module_group:)
      module_benefit = create(:module_benefit, plan_module:)
      wizard_progress.update!(current_step: "plan_modules", step_order: 4, status: :in_progress)
      progress = wizard_progress

      expect do
        patch wizard_progress_path(progress, format: :turbo_stream),
              params: { step_action: "delete", modules: { id: plan_module.id } }
      end.to change { plan.plan_modules.reload.count }.by(-1)
        .and change { ModuleBenefit.where(id: module_benefit.id).count }.by(-1)

      expect(response).to have_http_status(:success)
    end

    it "deletes a module benefit and cascades linked cost shares" do
      plan = wizard_progress.subject
      plan_version = plan.current_plan_version
      module_group = create(:module_group, plan_version:)
      plan_module = create(:plan_module, plan_version:, module_group:)
      module_benefit = create(:module_benefit, :with_deductible, plan_module:)
      benefit_limit_rule = create(:benefit_limit_rule, module_benefit:)
      wizard_progress.update!(current_step: "module_benefits", step_order: 6, status: :in_progress)
      progress = wizard_progress

      expect do
        patch wizard_progress_path(progress, format: :turbo_stream),
              params: { step_action: "delete", benefits: { id: module_benefit.id } }
      end.to change { ModuleBenefit.where(id: module_benefit.id).count }.by(-1)
        .and change { CostShare.where(scope: module_benefit).count }.by(-1)
        .and change { BenefitLimitRule.where(id: benefit_limit_rule.id).count }.by(-1)

      expect(response).to have_http_status(:success)
    end

    it "creates a module benefit with multiple benefit limit rules" do
      plan = wizard_progress.subject
      plan_version = plan.current_plan_version
      module_group = create(:module_group, plan_version:)
      plan_module = create(:plan_module, plan_version:, module_group:)
      benefit = create(:benefit)
      wizard_progress.update!(current_step: "module_benefits", step_order: 6, status: :in_progress)

      expect do
        patch wizard_progress_path(wizard_progress, format: :turbo_stream),
              params: {
                step_action: "add",
                benefits: {
                  plan_module_id: plan_module.id,
                  benefit_id: benefit.id,
                  coverage_description: "Covered with structured rules",
                  benefit_limit_rules_attributes: {
                    "0" => {
                      name: "MRI",
                      scope: "itemised",
                      limit_type: "amount",
                      insurer_amount_usd: "1200",
                      unit: "per policy year",
                      position: "0"
                    },
                    "1" => {
                      name: "CT",
                      scope: "itemised",
                      limit_type: "as_charged",
                      cap_insurer_amount_usd: "3000",
                      cap_unit: "per policy year",
                      position: "1"
                    }
                  }
                }
              }
      end.to change(ModuleBenefit, :count).by(1)
        .and change(BenefitLimitRule, :count).by(2)

      created = ModuleBenefit.order(:created_at).last
      expect(created.benefit_limit_rules.order(:position, :created_at).pluck(:name, :limit_type)).to eq(
        [ [ "MRI", "amount" ], [ "CT", "as_charged" ] ]
      )
      expect(response).to have_http_status(:success)
    end

    it "updates benefit limit rules when editing a module benefit" do
      plan = wizard_progress.subject
      plan_version = plan.current_plan_version
      module_group = create(:module_group, plan_version:)
      plan_module = create(:plan_module, plan_version:, module_group:)
      benefit = create(:benefit)
      module_benefit = create(:module_benefit, plan_module:, benefit:, coverage_description: "Before")
      first = create(:benefit_limit_rule, module_benefit:, scope: :itemised, name: "Old amount", limit_type: :amount, insurer_amount_usd: 500, position: 0)
      second = create(:benefit_limit_rule, module_benefit:, scope: :itemised, name: "Delete me", limit_type: :not_stated, position: 1)
      wizard_progress.update!(current_step: "module_benefits", step_order: 6, status: :in_progress)

      expect do
        patch wizard_progress_path(wizard_progress, format: :turbo_stream),
              params: {
                step_action: "add",
                benefits: {
                  id: module_benefit.id,
                  plan_module_id: plan_module.id,
                  benefit_id: benefit.id,
                  coverage_description: "After",
                  benefit_limit_rules_attributes: {
                    "0" => {
                      id: first.id,
                      name: "Updated amount",
                      scope: "itemised",
                      limit_type: "amount",
                      insurer_amount_usd: "950",
                      unit: "per examination",
                      position: "2"
                    },
                    "1" => {
                      id: second.id,
                      _destroy: "1"
                    },
                    "2" => {
                      name: "New as charged",
                      scope: "itemised",
                      limit_type: "as_charged",
                      cap_insurer_amount_usd: "500",
                      cap_unit: "per policy year",
                      position: "1"
                    }
                  }
                }
              }
      end.to change(BenefitLimitRule, :count).by(0)

      module_benefit.reload
      expect(module_benefit.coverage_description).to eq("After")
      expect(module_benefit.benefit_limit_rules.order(:position, :created_at).pluck(:name, :limit_type)).to eq(
        [ [ "New as charged", "as_charged" ], [ "Updated amount", "amount" ] ]
      )
      expect(module_benefit.benefit_limit_rules.where(id: second.id)).to be_empty
      expect(response).to have_http_status(:success)
    end

    it "deletes a benefit limit group and cascades its module benefits" do
      plan = wizard_progress.subject
      plan_version = plan.current_plan_version
      module_group = create(:module_group, plan_version:)
      plan_module = create(:plan_module, plan_version:, module_group:)
      benefit_limit_group = create(:benefit_limit_group, plan_module:)
      module_benefit = create(:module_benefit, :with_deductible, plan_module:, benefit_limit_group:)
      wizard_progress.update!(current_step: "benefit_limit_groups", step_order: 7, status: :in_progress)
      progress = wizard_progress

      expect do
        patch wizard_progress_path(progress, format: :turbo_stream),
              params: { step_action: "delete", benefit_limit_groups: { id: benefit_limit_group.id } }
      end.to change { BenefitLimitGroup.where(id: benefit_limit_group.id).count }.by(-1)
        .and change { ModuleBenefit.where(id: module_benefit.id).count }.by(-1)
        .and change { CostShare.where(scope: module_benefit).count }.by(-1)

      expect(response).to have_http_status(:success)
    end

    it "deletes a cost share regardless of scope" do
      plan = wizard_progress.subject
      plan_version = plan.current_plan_version
      module_group = create(:module_group, plan_version:)
      plan_module = create(:plan_module, plan_version:, module_group:)
      module_benefit = create(:module_benefit, plan_module:)
      benefit_limit_group = create(:benefit_limit_group, plan_module:)

      plan_cost_share = create(:cost_share, scope: plan_version, cost_share_type: :deductible, amount_usd: 100, per: :per_year)
      module_cost_share = create(:cost_share, scope: plan_module, cost_share_type: :excess, amount_usd: 10, unit: :amount, per: :per_visit)
      module_benefit_cost_share = create(:cost_share, scope: module_benefit, cost_share_type: :coinsurance, amount: 50, unit: :percent, per: :per_condition)
      benefit_limit_cost_share = create(:cost_share, scope: benefit_limit_group, cost_share_type: :excess, amount_usd: 75, per: :per_condition)

      wizard_progress.update!(current_step: "cost_shares", step_order: 8, status: :in_progress)
      progress = wizard_progress

      expect do
        patch wizard_progress_path(progress, format: :turbo_stream),
              params: { step_action: "delete", cost_shares: { id: plan_cost_share.id } }
      end.to change { CostShare.where(id: plan_cost_share.id).count }.by(-1)

      expect do
        patch wizard_progress_path(progress, format: :turbo_stream),
              params: { step_action: "delete", cost_shares: { id: module_cost_share.id } }
      end.to change { CostShare.where(id: module_cost_share.id).count }.by(-1)

      expect do
        patch wizard_progress_path(progress, format: :turbo_stream),
              params: { step_action: "delete", cost_shares: { id: module_benefit_cost_share.id } }
      end.to change { CostShare.where(id: module_benefit_cost_share.id).count }.by(-1)

      expect do
        patch wizard_progress_path(progress, format: :turbo_stream),
              params: { step_action: "delete", cost_shares: { id: benefit_limit_cost_share.id } }
      end.to change { CostShare.where(id: benefit_limit_cost_share.id).count }.by(-1)

      expect(response).to have_http_status(:success)
    end

    it "creates one cost share per selected benefit limit rule" do
      plan = wizard_progress.subject
      plan_version = plan.current_plan_version
      module_group = create(:module_group, plan_version:)
      plan_module = create(:plan_module, plan_version:, module_group:)
      module_benefit = create(:module_benefit, plan_module:)
      rule_a = create(:benefit_limit_rule, module_benefit:, scope: :itemised, name: "Extraction")
      rule_b = create(:benefit_limit_rule, module_benefit:, scope: :itemised, name: "Surgery")

      wizard_progress.update!(current_step: "cost_shares", step_order: 8, status: :in_progress)

      expect do
        patch wizard_progress_path(wizard_progress, format: :turbo_stream),
              params: {
                step_action: "add",
                cost_shares: {
                  applies_to: "benefit_limit_rule",
                  plan_module_id: plan_module.id,
                  module_benefit_id: module_benefit.id,
                  cost_share_type: "coinsurance",
                  amount: "80",
                  unit: "percent",
                  per: "per_visit",
                  benefit_limit_rule_ids: [ rule_a.id, rule_b.id ]
                }
              }
      end.to change { CostShare.where(scope_type: "BenefitLimitRule").count }.by(2)

      created = CostShare.where(scope_type: "BenefitLimitRule", scope_id: [ rule_a.id, rule_b.id ])
      expect(created.pluck(:kind).uniq).to eq([ "coinsurance" ])
      expect(created.pluck(:amount).uniq).to eq([ BigDecimal("80.0") ])
      expect(response).to have_http_status(:success)
    end

    it "updates existing rule-scoped cost shares instead of creating duplicates on repeated adds" do
      plan = wizard_progress.subject
      plan_version = plan.current_plan_version
      module_group = create(:module_group, plan_version:)
      plan_module = create(:plan_module, plan_version:, module_group:)
      module_benefit = create(:module_benefit, plan_module:)
      rule = create(:benefit_limit_rule, module_benefit:, scope: :itemised, name: "Extraction")

      wizard_progress.update!(current_step: "cost_shares", step_order: 8, status: :in_progress)

      expect do
        patch wizard_progress_path(wizard_progress, format: :turbo_stream),
              params: {
                step_action: "add",
                cost_shares: {
                  applies_to: "benefit_limit_rule",
                  plan_module_id: plan_module.id,
                  module_benefit_id: module_benefit.id,
                  cost_share_type: "coinsurance",
                  amount: "80",
                  unit: "percent",
                  per: "per_visit",
                  benefit_limit_rule_ids: [ rule.id ]
                }
              }
      end.to change { CostShare.where(scope_type: "BenefitLimitRule", scope_id: rule.id).count }.by(1)

      existing_cost_share = CostShare.find_by!(scope: rule)

      expect do
        patch wizard_progress_path(wizard_progress, format: :turbo_stream),
              params: {
                step_action: "add",
                cost_shares: {
                  applies_to: "benefit_limit_rule",
                  plan_module_id: plan_module.id,
                  module_benefit_id: module_benefit.id,
                  cost_share_type: "coinsurance",
                  amount: "65",
                  unit: "percent",
                  per: "per_year",
                  benefit_limit_rule_ids: [ rule.id ]
                }
              }
      end.not_to change { CostShare.where(scope_type: "BenefitLimitRule", scope_id: rule.id).count }

      updated_cost_share = CostShare.find_by!(scope: rule)
      expect(updated_cost_share.id).to eq(existing_cost_share.id)
      expect(updated_cost_share.amount).to eq(BigDecimal("65.0"))
      expect(updated_cost_share.per).to eq("per_year")
      expect(response).to have_http_status(:success)
    end

    it "deletes a cost share link" do
      plan = wizard_progress.subject
      plan_version = plan.current_plan_version
      module_group = create(:module_group, plan_version:)
      plan_module = create(:plan_module, plan_version:, module_group:)
      module_benefit = create(:module_benefit, plan_module:)

      primary = create(:cost_share, scope: plan_version, cost_share_type: :deductible, amount_usd: 100, per: :per_year)
      secondary = create(:cost_share, scope: module_benefit, cost_share_type: :coinsurance, amount: 20, unit: :percent, per: :per_visit)
      cost_share_link = create(:cost_share_link, cost_share: primary, linked_cost_share: secondary, relationship_type: :shared_pool)

      wizard_progress.update!(current_step: "cost_share_links", step_order: 9, status: :in_progress)
      progress = wizard_progress

      expect do
        patch wizard_progress_path(progress, format: :turbo_stream),
              params: { step_action: "delete", cost_share_links: { id: cost_share_link.id } }
      end.to change { CostShareLink.where(id: cost_share_link.id).count }.by(-1)

      expect(response).to have_http_status(:success)
    end
  end
end
