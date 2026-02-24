require "rails_helper"

RSpec.describe BenefitLimitRule, type: :model do
  subject(:benefit_limit_rule) { build(:benefit_limit_rule) }

  it { expect(benefit_limit_rule).to belong_to(:module_benefit) }
  it { expect(benefit_limit_rule).to have_one(:cost_share).dependent(:destroy) }
  it { expect(benefit_limit_rule).to validate_presence_of(:scope) }
  it { expect(benefit_limit_rule).to validate_presence_of(:limit_type) }
  it { expect(benefit_limit_rule).to define_enum_for(:scope).with_values(benefit_level: 0, itemised: 1) }
  it { expect(benefit_limit_rule).to define_enum_for(:limit_type).with_values(amount: 0, as_charged: 1, not_stated: 2) }

  describe "name rules" do
    it "requires a name for itemised scope" do
      benefit_limit_rule.assign_attributes(scope: :itemised, name: nil)

      expect(benefit_limit_rule).not_to be_valid
      expect(benefit_limit_rule.errors[:name]).to include("can't be blank")
    end

    it "allows a blank name for benefit-level scope" do
      benefit_limit_rule.assign_attributes(scope: :benefit_level, name: nil)

      expect(benefit_limit_rule).to be_valid
    end
  end

  describe "amount limits" do
    it "require at least one currency amount" do
      benefit_limit_rule.assign_attributes(limit_type: :amount, insurer_amount_usd: nil, insurer_amount_gbp: nil, insurer_amount_eur: nil)

      expect(benefit_limit_rule).not_to be_valid
      expect(benefit_limit_rule.errors[:base]).to include("Amount limit rules require at least one currency amount")
    end

    it "requires a unit" do
      benefit_limit_rule.assign_attributes(limit_type: :amount, unit: nil)
      expect(benefit_limit_rule).not_to be_valid
      expect(benefit_limit_rule.errors[:unit]).to include("can't be blank")
    end
  end

  describe "as charged and not stated limits" do
    it "do not allow insurer amounts or units" do
      benefit_limit_rule.assign_attributes(
        limit_type: :as_charged,
        insurer_amount_usd: 100,
        unit: "per session"
      )

      expect(benefit_limit_rule).not_to be_valid
      expect(benefit_limit_rule.errors[:base]).to include("As charged and not stated rules cannot include insurer amount or unit")
    end

    it "does not allow caps for not_stated" do
      benefit_limit_rule.assign_attributes(
        limit_type: :not_stated,
        cap_insurer_amount_usd: 500,
        cap_unit: "per policy year"
      )

      expect(benefit_limit_rule).not_to be_valid
      expect(benefit_limit_rule.errors[:base]).to include("Not stated rules cannot include cap values")
    end
  end

  describe "cap rules" do
    it "require cap_unit when a cap amount is present" do
      benefit_limit_rule.assign_attributes(cap_insurer_amount_usd: 500, cap_unit: nil)

      expect(benefit_limit_rule).not_to be_valid
      expect(benefit_limit_rule.errors[:cap_unit]).to include("can't be blank when a cap amount is provided")
    end
  end
end
