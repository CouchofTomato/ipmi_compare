require "rails_helper"

RSpec.describe ModuleBenefit, type: :model do
  subject(:module_benefit) { create(:module_benefit) }

  it { expect(module_benefit).to belong_to(:plan_module) }
  it { expect(module_benefit).to belong_to(:benefit) }
  it { expect(module_benefit).to belong_to(:benefit_limit_group).optional(true) }
  it { expect(module_benefit).to have_many(:benefit_limit_rules).dependent(:destroy) }
  it { expect(module_benefit).to have_many(:cost_shares).dependent(:destroy) }

  it { should define_enum_for(:interaction_type).with_values(replace: 0, append: 1) }

  it { expect(module_benefit).to validate_presence_of(:benefit) }
  it { expect(module_benefit).to validate_presence_of(:plan_module) }
  it { expect(module_benefit).to validate_numericality_of(:weighting).only_integer }

  describe "coverage_or_limit_must_be_present" do
    it "is invalid without coverage description and without limit rules" do
      module_benefit = build(:module_benefit, coverage_description: nil)

      expect(module_benefit).not_to be_valid
      expect(module_benefit.errors[:base]).to include(
        "Either a coverage description or at least one benefit limit rule must be present"
      )
    end

    it "is valid with coverage description only" do
      module_benefit = build(:module_benefit, coverage_description: "Covered")
      expect(module_benefit).to be_valid
    end

    it "is valid with benefit limit rules only" do
      module_benefit = build(:module_benefit, coverage_description: nil)
      module_benefit.benefit_limit_rules.build(
        scope: :benefit_level,
        limit_type: :amount,
        insurer_amount_usd: 1200,
        unit: "per policy year"
      )

      expect(module_benefit).to be_valid
    end
  end

  describe "numeric limit fields" do
    it "does not expose numeric limit columns on module_benefits" do
      columns = described_class.column_names
      expect(columns).not_to include("limit_usd", "limit_gbp", "limit_eur", "limit_unit")
    end
  end

  describe "#coverage_category" do
    it "delegates to the benefit" do
      category = create(:coverage_category, name: "Inpatient")
      benefit = create(:benefit, coverage_category: category)
      module_benefit = create(:module_benefit, benefit: benefit)

      expect(module_benefit.coverage_category).to eq(category)
    end
  end

  describe "dependent destroy" do
    it "destroys benefit limit rules when module benefit is destroyed" do
      module_benefit = create(:module_benefit)
      rule = create(:benefit_limit_rule, module_benefit: module_benefit)

      expect { module_benefit.destroy }.to change { BenefitLimitRule.where(id: rule.id).count }.by(-1)
    end
  end
end
