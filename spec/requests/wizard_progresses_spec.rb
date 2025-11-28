require "rails_helper"

RSpec.describe "WizardProgresses", type: :request do
  let(:wizard_progress) do
    create(
      :wizard_progress,
      wizard_type: "plan_creation",
      current_step: "plan_residency"
    )
  end

  before do
    sign_in wizard_progress.user
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

    it "deletes a module group that has no modules" do
      plan = wizard_progress.subject
      module_group = create(:module_group, plan:)
      progress = create(:wizard_progress,
                        wizard_type: "plan_creation",
                        subject: plan,
                        user: wizard_progress.user,
                        current_step: "module_groups",
                        step_order: 3)

      expect do
        patch wizard_progress_path(progress, format: :turbo_stream),
              params: { step_action: "delete", module_groups: { id: module_group.id } }
      end.to change { plan.module_groups.reload.count }.by(-1)

      expect(response).to have_http_status(:success)
    end

    it "deletes a module group and cascades plan modules" do
      plan = wizard_progress.subject
      module_group = create(:module_group, plan:)
      plan_module = create(:plan_module, plan:, module_group:)
      progress = create(:wizard_progress,
                        wizard_type: "plan_creation",
                        subject: plan,
                        user: wizard_progress.user,
                        current_step: "module_groups",
                        step_order: 3)

      expect do
        patch wizard_progress_path(progress, format: :turbo_stream),
              params: { step_action: "delete", module_groups: { id: module_group.id } }
      end.to change { plan.module_groups.reload.count }.by(-1)
        .and change { PlanModule.where(id: plan_module.id).count }.by(-1)

      expect(response).to have_http_status(:success)
    end

    it "deletes a plan module and cascades related objects" do
      plan = wizard_progress.subject
      module_group = create(:module_group, plan:)
      plan_module = create(:plan_module, plan:, module_group:)
      module_benefit = create(:module_benefit, plan_module:)
      progress = create(:wizard_progress,
                        wizard_type: "plan_creation",
                        subject: plan,
                        user: wizard_progress.user,
                        current_step: "plan_modules",
                        step_order: 4)

      expect do
        patch wizard_progress_path(progress, format: :turbo_stream),
              params: { step_action: "delete", modules: { id: plan_module.id } }
      end.to change { plan.plan_modules.reload.count }.by(-1)
        .and change { ModuleBenefit.where(id: module_benefit.id).count }.by(-1)

      expect(response).to have_http_status(:success)
    end

    it "deletes a module benefit and cascades linked cost shares" do
      plan = wizard_progress.subject
      module_group = create(:module_group, plan:)
      plan_module = create(:plan_module, plan:, module_group:)
      module_benefit = create(:module_benefit, :with_deductible, plan_module:)
      progress = create(:wizard_progress,
                        wizard_type: "plan_creation",
                        subject: plan,
                        user: wizard_progress.user,
                        current_step: "module_benefits",
                        step_order: 5)

      expect do
        patch wizard_progress_path(progress, format: :turbo_stream),
              params: { step_action: "delete", benefits: { id: module_benefit.id } }
      end.to change { ModuleBenefit.where(id: module_benefit.id).count }.by(-1)
        .and change { CostShare.where(scope: module_benefit).count }.by(-1)

      expect(response).to have_http_status(:success)
    end

    it "deletes a benefit limit group and cascades its module benefits" do
      plan = wizard_progress.subject
      module_group = create(:module_group, plan:)
      plan_module = create(:plan_module, plan:, module_group:)
      benefit_limit_group = create(:benefit_limit_group, plan_module:)
      module_benefit = create(:module_benefit, :with_deductible, plan_module:, benefit_limit_group:)
      progress = create(:wizard_progress,
                        wizard_type: "plan_creation",
                        subject: plan,
                        user: wizard_progress.user,
                        current_step: "benefit_limit_groups",
                        step_order: 6)

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
      module_group = create(:module_group, plan:)
      plan_module = create(:plan_module, plan:, module_group:)
      module_benefit = create(:module_benefit, plan_module:)
      benefit_limit_group = create(:benefit_limit_group, plan_module:)

      plan_cost_share = create(:cost_share, scope: plan, cost_share_type: :deductible, amount: 100, per: :per_year, currency: "USD")
      module_cost_share = create(:cost_share, scope: plan_module, cost_share_type: :coinsurance, amount: 10, unit: :percent, per: :per_visit)
      module_benefit_cost_share = create(:cost_share, scope: module_benefit, cost_share_type: :excess, amount: 50, per: :per_condition, currency: "USD")
      benefit_limit_cost_share = create(:cost_share, scope: benefit_limit_group, cost_share_type: :excess, amount: 75, per: :per_condition, currency: "USD")

      progress = create(:wizard_progress,
                        wizard_type: "plan_creation",
                        subject: plan,
                        user: wizard_progress.user,
                        current_step: "cost_shares",
                        step_order: 7)

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
  end
end
