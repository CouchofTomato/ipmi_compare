require 'rails_helper'

RSpec.describe BenefitLimitGroup, type: :model do
  subject(:benefit_limit_group) { create(:benefit_limit_group) }

  #== Associations =============================================================
  it { expect(benefit_limit_group).to belong_to(:plan_module) }
  it { expect(benefit_limit_group).to have_many(:module_benefits).dependent(:destroy) }
  it { expect(benefit_limit_group).to have_many(:benefit_limit_group_rules).dependent(:destroy) }
  it { expect(benefit_limit_group).to have_many(:cost_shares).dependent(:destroy) }
  it { expect(benefit_limit_group).to have_many(:deductibles).class_name("CostShare") }
  it { expect(benefit_limit_group).to have_many(:coinsurances).class_name("CostShare") }
  it { expect(benefit_limit_group).to have_many(:excesses).class_name("CostShare") }

  #== Validations ============================================================
  it { expect(benefit_limit_group).to validate_presence_of(:name) }

  describe "shared limit rule presence" do
    it "is invalid without shared rules or legacy limit data" do
      benefit_limit_group.limit_usd = nil
      benefit_limit_group.limit_gbp = nil
      benefit_limit_group.limit_eur = nil
      benefit_limit_group.limit_unit = nil

      expect(benefit_limit_group).not_to be_valid
      expect(benefit_limit_group.errors[:base]).to include("Add at least one shared limit rule")
    end

    it "is valid with a shared rule and no legacy limit columns" do
      group = build(:benefit_limit_group, :with_shared_limit_rule)

      expect(group).to be_valid
    end

    it "is valid with legacy limit columns during transition" do
      group = build(:benefit_limit_group, limit_usd: 1000, limit_unit: "per policy year")

      expect(group).to be_valid
    end
  end
end
