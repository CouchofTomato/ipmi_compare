require "rails_helper"

RSpec.describe WizardFlow do
  describe ".for" do
    subject(:flow_for) { described_class.for(wizard) }

    let(:wizard) { instance_double("WizardProgress", wizard_type: wizard_type) }

    context "when wizard_type is plan_creation" do
      let(:wizard_type) { "plan_creation" }
      let(:plan_flow_instance) { instance_double("PlanWizardFlow") }
      let(:plan_flow_class) { class_double("PlanWizardFlow") }

      before do
        stub_const("PlanWizardFlow", plan_flow_class)
        allow(plan_flow_class).to receive(:new).with(wizard).and_return(plan_flow_instance)
      end

      it "instantiates the PlanWizardFlow with the wizard" do
        expect(flow_for).to eq(plan_flow_instance)
        expect(plan_flow_class).to have_received(:new).with(wizard)
      end
    end

    context "when wizard_type is not recognized" do
      let(:wizard_type) { "unknown_wizard" }

      it "raises an ArgumentError" do
        expect { flow_for }.to raise_error(ArgumentError, "Unknown wizard type: #{wizard_type}")
      end
    end
  end
end
