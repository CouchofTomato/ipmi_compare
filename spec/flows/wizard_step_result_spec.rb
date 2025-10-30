require "rails_helper"

RSpec.describe WizardStepResult do
  describe "#success?" do
    it "returns true when initialized with success: true" do
      result = described_class.new(success: true)

      expect(result.success?).to be(true)
    end

    it "returns false when initialized with success: false" do
      result = described_class.new(success: false)

      expect(result.success?).to be(false)
    end
  end

  describe "#failure?" do
    it "is the inverse of success?" do
      success_result = described_class.new(success: true)
      failure_result = described_class.new(success: false)

      expect(success_result.failure?).to be(false)
      expect(failure_result.failure?).to be(true)
    end
  end

  describe "attr readers" do
    it "exposes the resource" do
      resource = double(:resource)
      result = described_class.new(success: true, resource: resource)

      expect(result.resource).to be(resource)
    end

    it "exposes the errors collection" do
      errors = ["invalid attributes"]
      result = described_class.new(success: false, errors: errors)

      expect(result.errors).to eq(errors)
    end
  end
end
