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
    shared_group = create(:benefit_limit_group, :with_shared_limit_rule, plan_module: module_one, name: "Outpatient therapies shared limit")
    shared_group.benefit_limit_group_rules.first.update!(
      rule_type: :usage,
      amount_usd: nil,
      amount_gbp: nil,
      amount_eur: nil,
      quantity_value: 15,
      quantity_unit_kind: :consultation,
      period_kind: :rolling_days,
      period_value: 30
    )
    module_benefit_one = create(:module_benefit, plan_module: module_one, benefit: benefit_a, coverage_description: "Covered", benefit_limit_group: shared_group)
    create(:benefit_limit_rule, module_benefit: module_benefit_one, scope: :itemised, name: "MRI", limit_type: :amount, insurer_amount_gbp: 750, unit: "per examination", position: 0)
    create(:module_benefit, plan_module: module_two, benefit: benefit_b, coverage_description: "Included")
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
      expect(per_selection["sel-one"].first[:itemised_limit_rules].map { |rule| rule[:name] }).to eq([ "MRI" ])
      expect(per_selection["sel-one"].first[:benefit_limit_group_name]).to eq("Outpatient therapies shared limit")
      expect(per_selection["sel-one"].first[:benefit_limit_group_rule_text]).to eq("15 consultations in a 30 day period")
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

    it "appends all entries when all matching module benefits are append" do
      create(:module_benefit, plan_module: module_one, benefit: benefit_a, coverage_description: "Append low", interaction_type: :append, weighting: 1)
      create(:module_benefit, plan_module: module_one, benefit: benefit_a, coverage_description: "Append high", interaction_type: :append, weighting: 10)

      result = described_class.new(progress).build
      inpatient = result[:categories].find { |cat| cat[:id] == category_a.id }
      per_selection = inpatient[:benefits].find { |b| b[:id] == benefit_a.id }[:per_selection]

      expect(per_selection["sel-one"].map { |entry| entry[:coverage_description] }).to include("Append low", "Append high")
    end

    it "uses only the highest-weighted replace entry when replace module benefits exist" do
      create(:module_benefit, plan_module: module_one, benefit: benefit_a, coverage_description: "Append text", interaction_type: :append, weighting: 3)
      create(:module_benefit, plan_module: module_one, benefit: benefit_a, coverage_description: "Replace low", interaction_type: :replace, weighting: 5)
      create(:module_benefit, plan_module: module_one, benefit: benefit_a, coverage_description: "Replace high", interaction_type: :replace, weighting: 15)

      result = described_class.new(progress).build
      inpatient = result[:categories].find { |cat| cat[:id] == category_a.id }
      per_selection = inpatient[:benefits].find { |b| b[:id] == benefit_a.id }[:per_selection]

      expect(per_selection["sel-one"].size).to eq(1)
      expect(per_selection["sel-one"].first[:coverage_description]).to eq("Replace high")
    end
  end
end
