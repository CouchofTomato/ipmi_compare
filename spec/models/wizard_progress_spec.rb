require 'rails_helper'

RSpec.describe WizardProgress, type: :model do
  subject(:wizard_progress) { create(:wizard_progress) }

  #== Associations ===========================================================
  it { expect(wizard_progress).to belong_to(:entity) }
  it { expect(wizard_progress).to belong_to(:last_actor).class_name("User").optional }

  #== Validations ============================================================
  it { expect(wizard_progress).to validate_presence_of(:wizard_type) }
  it { expect(wizard_progress).to validate_presence_of(:current_step) }
  it { expect(wizard_progress).to validate_presence_of(:started_at) }
  it { expect(wizard_progress).to validate_presence_of(:step_order) }
  it { expect(wizard_progress).to validate_numericality_of(:step_order).is_greater_than_or_equal_to(0).only_integer }
  it { expect(wizard_progress).to validate_uniqueness_of(:wizard_type).scoped_to(:entity_type, :entity_id) }

  #== Enums ===================================================================
  it { expect(wizard_progress).to define_enum_for(:status).with_values(in_progress: "in_progress", complete: "complete", abandoned: "abandoned", expired: "expired").backed_by_column_of_type(:string) }

  describe "#flow" do
    subject(:wizard_progress) { build(:wizard_progress) }

    let(:flow) { instance_double("WizardFlow") }
    let(:wizard_flow_class) { class_double("WizardFlow").as_stubbed_const }

    before do
      allow(wizard_flow_class).to receive(:for).with(wizard_progress).and_return(flow)
    end

    it "returns the flow from WizardFlow.for" do
      expect(wizard_progress.flow).to eq(flow)
    end
  end

  describe "step helpers" do
    subject(:wizard_progress) { build(:wizard_progress, current_step: current_step) }

    let(:steps) { %w[plan_details contacts review] }
    let(:flow) { instance_double("WizardFlow", steps: steps) }
    let(:wizard_flow_class) { class_double("WizardFlow").as_stubbed_const }

    before do
      allow(wizard_flow_class).to receive(:for).with(wizard_progress).and_return(flow)
    end

    context "when the current step is part of the flow" do
      let(:current_step) { "contacts" }

      it "returns the list of steps from the flow" do
        expect(wizard_progress.steps).to eq(steps)
      end

      it "returns the index of the current step" do
        expect(wizard_progress.current_step_index).to eq(1)
      end

      it "returns the next step" do
        expect(wizard_progress.next_step).to eq("review")
      end

      it "returns the previous step" do
        expect(wizard_progress.previous_step).to eq("plan_details")
      end

      it "calculates the percentage of progress through the flow" do
        expect(wizard_progress.progress).to eq(50)
      end
    end

    context "when the current step is the first in the flow" do
      let(:current_step) { "plan_details" }

      it "does not return a previous step" do
        expect(wizard_progress.previous_step).to be_nil
      end
    end

    context "when the current step is the last in the flow" do
      let(:current_step) { "review" }

      it "does not return a next step" do
        expect(wizard_progress.next_step).to be_nil
      end
    end

    context "when the current step does not exist in the flow" do
      let(:current_step) { "missing_step" }

      it "defaults the current step index to zero" do
        expect(wizard_progress.current_step_index).to eq(0)
      end
    end
  end
end
