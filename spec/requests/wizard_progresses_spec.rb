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
  end
end
