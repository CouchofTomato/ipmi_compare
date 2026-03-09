require "rails_helper"

RSpec.describe BenefitLimitGroupRule, type: :model do
  subject(:rule) { build(:benefit_limit_group_rule) }

  it { expect(rule).to belong_to(:benefit_limit_group) }
  it { expect(rule).to validate_presence_of(:rule_type) }
  it { expect(rule).to validate_presence_of(:period_kind) }

  describe "validations" do
    it "requires at least one amount for amount rule" do
      rule.amount_usd = nil
      rule.amount_gbp = nil
      rule.amount_eur = nil

      expect(rule).not_to be_valid
      expect(rule.errors[:base]).to include("Amount rules require at least one currency amount")
    end

    it "requires quantity fields for usage rules" do
      rule.rule_type = :usage
      rule.amount_usd = nil
      rule.quantity_value = nil
      rule.quantity_unit_kind = nil

      expect(rule).not_to be_valid
      expect(rule.errors[:quantity_value]).to include("can't be blank")
      expect(rule.errors[:quantity_unit_kind]).to include("can't be blank")
    end

    it "requires period value for rolling periods" do
      rule.period_kind = :rolling_days
      rule.period_value = nil

      expect(rule).not_to be_valid
      expect(rule.errors[:period_value]).to include("can't be blank")
    end

    it "requires custom unit when quantity unit is other" do
      rule.rule_type = :usage
      rule.amount_usd = nil
      rule.quantity_value = 5
      rule.quantity_unit_kind = :other
      rule.quantity_unit_custom = nil

      expect(rule).not_to be_valid
      expect(rule.errors[:quantity_unit_custom]).to include("can't be blank when unit is other")
    end
  end
end
