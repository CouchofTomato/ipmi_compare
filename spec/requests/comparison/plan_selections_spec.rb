require "rails_helper"

RSpec.describe "Comparison::PlanSelections", type: :request do
  let(:progress) { create(:wizard_progress, :plan_comparison) }
  let(:plan)     { create(:plan) }
  let(:group)    { create(:module_group, plan:) }
  let(:module_a) { create(:plan_module, plan:, module_group: group) }
  let(:module_b) { create(:plan_module, plan:, module_group: group, name: "Alternate") }

  describe "GET /search" do
    it "returns success" do
      get search_comparison_plan_selection_path(progress), params: { q: plan.name }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /add" do
    it "stores a new selection with chosen modules" do
      post add_comparison_plan_selection_path(progress),
           params: { plan_id: plan.id, module_groups: { group.id => module_a.id } }

      progress.reload
      selections = progress.state["plan_selections"]

      expect(response).to redirect_to(wizard_progress_path(progress))
      expect(selections.size).to eq(1)
      expect(selections.first).to include(
        "plan_id" => plan.id,
        "module_groups" => { group.id.to_s => module_a.id }
      )
      expect(selections.first["id"]).to be_present
    end

    it "allows the same plan with different module selections" do
      progress.update!(
        state: {
          "plan_selections" => [
            { "id" => "existing", "plan_id" => plan.id, "module_groups" => { group.id.to_s => module_a.id } }
          ]
        }
      )

      expect do
        post add_comparison_plan_selection_path(progress),
             params: { plan_id: plan.id, module_groups: { group.id => module_b.id } }
      end.to change { progress.reload.state["plan_selections"].size }.by(1)
    end

    it "rejects duplicate plan/module combinations" do
      progress.update!(
        state: {
          "plan_selections" => [
            { "id" => "existing", "plan_id" => plan.id, "module_groups" => { group.id.to_s => module_a.id } }
          ]
        }
      )

      expect do
        post add_comparison_plan_selection_path(progress),
             params: { plan_id: plan.id, module_groups: { group.id => module_a.id } }
      end.not_to change { progress.reload.state["plan_selections"].size }

      expect(flash[:alert]).to eq("This plan with the same modules is already added.")
    end
  end

  describe "DELETE /remove" do
    it "removes the targeted selection" do
      progress.update!(
        state: {
          "plan_selections" => [
            { "id" => "keep", "plan_id" => plan.id, "module_groups" => { group.id.to_s => module_a.id } },
            { "id" => "delete_me", "plan_id" => plan.id, "module_groups" => { group.id.to_s => module_b.id } }
          ]
        }
      )

      expect do
        delete remove_comparison_plan_selection_path(progress), params: { selection_id: "delete_me", plan_id: plan.id }
      end.to change { progress.reload.state["plan_selections"].map { |s| s["id"] } }.from(%w[keep delete_me]).to(%w[keep])

      expect(response).to redirect_to(wizard_progress_path(progress))
    end
  end
end
