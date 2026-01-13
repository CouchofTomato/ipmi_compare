require "rails_helper"

RSpec.describe PlanWizardFlow do
  describe "#save_review" do
    let(:plan) { create(:plan, published: true, version_year: 2024, effective_on: Date.new(2024, 1, 1)) }
    let(:current_version) { plan.current_plan_version }
    let(:draft_version_attrs) do
      {
        version_year: 2025,
        effective_on: Date.new(2025, 1, 1),
        effective_through: nil,
        min_age: 0,
        max_age: 65,
        children_only_allowed: false,
        published: false,
        policy_type: :company,
        last_reviewed_at: Date.new(2025, 10, 6),
        next_review_due: Date.new(2025, 10, 6),
        review_notes: "Draft notes",
        current: false
      }
    end
    let!(:draft_version) { plan.plan_versions.create!(draft_version_attrs) }
    let(:wizard_progress) do
      create(
        :wizard_progress,
        wizard_type: "plan_creation",
        subject: plan,
        current_step: "review",
        step_order: 9,
        metadata: { "plan_version_id" => draft_version.id }
      )
    end
    let(:flow) { described_class.new(wizard_progress) }

    before do
      current_version.update!(published: true, effective_on: Date.new(2024, 1, 1), version_year: 2024)
    end

    it "auto-closes the previous published version when publishing a new one" do
      result = flow.save_review(ActionController::Parameters.new(publish_now: true), "complete")

      expect(result).to be_success
      expect(draft_version.reload).to be_published
      expect(draft_version).to be_current
      expect(current_version.reload.current).to be(false)
      expect(current_version.effective_through).to eq(Date.new(2024, 12, 31))
    end
  end
end
