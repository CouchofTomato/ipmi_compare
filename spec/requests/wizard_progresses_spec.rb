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

  describe "PATCH /update" do
    it "returns http success for turbo stream submissions" do
      expect do
        patch wizard_progress_path(wizard_progress, format: :turbo_stream),
              params: { step_action: "next" }
      end.to change { wizard_progress.reload.current_step }
        .from("plan_residency").to("geographic_cover_areas")

      expect(response).to have_http_status(:success)
    end
  end
end
