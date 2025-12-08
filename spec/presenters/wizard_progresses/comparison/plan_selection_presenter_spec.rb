require "rails_helper"

RSpec.describe WizardProgresses::Comparison::PlanSelectionPresenter do
  let(:plan) { create(:plan) }
  let(:group) { create(:module_group, plan:) }
  let(:module_a) { create(:plan_module, plan:, module_group: group, name: "A") }
  let(:module_b) { create(:plan_module, plan:, module_group: group, name: "B") }

  let(:progress) do
    create(
      :wizard_progress,
      :plan_comparison,
      state: {
        "plan_selections" => [
          { "id" => "one", "plan_id" => plan.id, "module_groups" => { group.id.to_s => module_a.id } },
          { "id" => "two", "plan_id" => plan.id, "module_groups" => { group.id.to_s => module_b.id } }
        ]
      }
    )
  end

  subject(:presenter) { described_class.new(progress) }

  describe "#saved_plan_selections" do
    it "returns selections with plan and module pairs" do
      result = presenter.saved_plan_selections

      expect(result.size).to eq(2)
      expect(result.first[:id]).to eq("one")
      expect(result.first[:plan]).to eq(plan)
      expect(result.first[:modules]).to eq([ [ group, module_a ] ])
      expect(result.second[:modules]).to eq([ [ group, module_b ] ])
    end

    it "handles a hash-based state for backwards compatibility" do
      progress.update!(
        state: {
          "plan_selections" => {
            "legacy" => { "plan_id" => plan.id, "module_groups" => { group.id.to_s => module_a.id } }
          }
        }
      )

      result = presenter.saved_plan_selections

      expect(result.size).to eq(1)
      expect(result.first[:plan]).to eq(plan)
      expect(result.first[:modules]).to eq([ [ group, module_a ] ])
    end
  end
end
