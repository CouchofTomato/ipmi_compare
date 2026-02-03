require "rails_helper"

RSpec.describe ComparisonBuilder do
  let(:user) { create(:user) }
  let(:category_a) { create(:coverage_category, name: "Inpatient", position: 1) }
  let(:category_b) { create(:coverage_category, name: "Outpatient", position: 2) }
  let(:category_empty) { create(:coverage_category, name: "Dental test #{SecureRandom.hex(4)}", position: 3) }

  let(:benefit_a) { create(:benefit, name: "Hospital stay", coverage_category: category_a) }
  let(:benefit_b) { create(:benefit, name: "Consultations", coverage_category: category_b) }
  let(:benefit_uncovered) { create(:benefit, name: "Dental cleaning", coverage_category: category_empty) }

  let(:plan_one) { create(:plan) }
  let(:plan_two) { create(:plan) }

  let(:version_one) { plan_one.current_plan_version }
  let(:version_two) { plan_two.current_plan_version }

  let(:group_one) { create(:module_group, plan_version: version_one) }
  let(:group_two) { create(:module_group, plan_version: version_two) }

  let(:module_one) { create(:plan_module, plan_version: version_one, module_group: group_one, name: "Core") }
  let(:module_two) { create(:plan_module, plan_version: version_two, module_group: group_two, name: "Premium") }
  let(:module_other) { create(:plan_module, plan_version: version_one, module_group: group_one, name: "Optional") }

  let(:progress) do
    create(
      :wizard_progress,
      :plan_comparison,
      user: user,
      state: {
        "plan_selections" => [
          { "id" => "sel-one", "plan_id" => plan_one.id, "module_groups" => { group_one.id.to_s => module_one.id } },
          { "id" => "sel-two", "plan_id" => plan_two.id, "module_groups" => { group_two.id.to_s => module_two.id } }
        ]
      }
    )
  end

  before do
    create(:module_benefit, plan_module: module_one, benefit: benefit_a, coverage_description: "Covered", limit_gbp: 10_000, limit_unit: "per year")
    create(:module_benefit, plan_module: module_two, benefit: benefit_b, coverage_description: "Included", limit_usd: 5000, limit_unit: "per visit")
    create(:module_benefit, plan_module: module_other, benefit: benefit_a, coverage_description: "Not selected")
    benefit_uncovered
  end

  describe "#build" do
    it "returns comparison data grouped by coverage category using selected modules" do
      result = described_class.new(progress).build

      expect(result[:selections].size).to eq(2)
      expect(result[:categories].map { |cat| cat[:name] }).to include("Inpatient", "Outpatient")

      inpatient = result[:categories].find { |cat| cat[:id] == category_a.id }
      expect(inpatient[:benefits].map { |b| b[:id] }).to include(benefit_a.id)

      per_selection = inpatient[:benefits].find { |b| b[:id] == benefit_a.id }[:per_selection]
      expect(per_selection["sel-one"].first[:coverage_description]).to eq("Covered")
      expect(per_selection["sel-two"]).to eq([])
    end

    it "includes categories with uncovered benefits" do
      result = described_class.new(progress).build

      expect(result[:categories].map { |cat| cat[:id] }).to include(category_empty.id)

      dental = result[:categories].find { |cat| cat[:id] == category_empty.id }
      expect(dental[:benefits].map { |b| b[:id] }).to include(benefit_uncovered.id)

      per_selection = dental[:benefits].find { |b| b[:id] == benefit_uncovered.id }[:per_selection]
      expect(per_selection["sel-one"]).to eq([])
      expect(per_selection["sel-two"]).to eq([])
    end
  end
end
