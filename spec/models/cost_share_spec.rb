require 'rails_helper'

RSpec.describe CostShare, type: :model do
  subject(:cost_share) { create(:cost_share) }

  it { is_expected.to belong_to(:scope) }
  it { is_expected.to have_many(:cost_share_links).dependent(:destroy) }
  it { is_expected.to have_many(:linked_cost_shares).through(:cost_share_links) }
  it { is_expected.to have_many(:reverse_cost_share_links).class_name("CostShareLink").with_foreign_key(:linked_cost_share_id).dependent(:destroy) }
  it { is_expected.to have_many(:parent_cost_shares).through(:reverse_cost_share_links) }

  it { expect(cost_share).to define_enum_for(:cost_share_type).with_values(deductible: 0, excess: 1, coinsurance: 2) }
  it { expect(cost_share).to define_enum_for(:kind).with_values(deductible: 0, coinsurance: 1) }
  it { expect(cost_share).to define_enum_for(:unit).with_values(amount: 0, percent: 1) }
  it { expect(cost_share).to define_enum_for(:per).with_values(per_visit: 0, per_condition: 1, per_year: 2, per_event: 3) }
  it { expect(cost_share).to define_enum_for(:cap_period).with_values(per_year: 0, per_condition: 1, per_admission: 2).with_prefix(:cap) }

  it { expect(cost_share).to validate_presence_of(:scope) }
  it { expect(cost_share).to validate_presence_of(:cost_share_type) }
  it { expect(cost_share).to validate_presence_of(:unit) }
  it { expect(cost_share).to validate_presence_of(:per) }

  it "supports BenefitLimitRule as a scope" do
    rule = create(:benefit_limit_rule)
    scoped_cost_share = build(:cost_share, scope: rule, cost_share_type: :coinsurance, amount: 80, unit: :percent)

    expect(scoped_cost_share).to be_valid
    expect(scoped_cost_share.scope).to eq(rule)
  end

  it "derives deductible kind from deductible type" do
    scoped_cost_share = build(:cost_share, scope: create(:plan_version), cost_share_type: :deductible, unit: :amount)

    scoped_cost_share.validate

    expect(scoped_cost_share.kind).to eq("deductible")
  end

  it "derives deductible kind from excess type" do
    scoped_cost_share = build(:cost_share, scope: create(:plan_module), cost_share_type: :excess, unit: :amount)

    scoped_cost_share.validate

    expect(scoped_cost_share.kind).to eq("deductible")
  end

  it "derives coinsurance kind from coinsurance type" do
    scoped_cost_share = build(:cost_share, scope: create(:module_benefit), cost_share_type: :coinsurance, unit: :percent)

    scoped_cost_share.validate

    expect(scoped_cost_share.kind).to eq("coinsurance")
  end

  it "disallows coinsurance type for PlanVersion scope" do
    scoped_cost_share = build(:cost_share, scope: create(:plan_version), cost_share_type: :coinsurance, unit: :percent)

    expect(scoped_cost_share).not_to be_valid
    expect(scoped_cost_share.errors[:cost_share_type]).to include("must be deductible or excess for plan, module, and benefit limit group cost shares")
  end

  it "disallows coinsurance type for PlanModule scope" do
    scoped_cost_share = build(:cost_share, scope: create(:plan_module), cost_share_type: :coinsurance, unit: :percent)

    expect(scoped_cost_share).not_to be_valid
    expect(scoped_cost_share.errors[:cost_share_type]).to include("must be deductible or excess for plan, module, and benefit limit group cost shares")
  end

  it "requires coinsurance type for ModuleBenefit scope" do
    scoped_cost_share = build(:cost_share, scope: create(:module_benefit), cost_share_type: :deductible, unit: :amount)

    expect(scoped_cost_share).not_to be_valid
    expect(scoped_cost_share.errors[:cost_share_type]).to include("must be coinsurance for benefit and rule cost shares")
  end

  it "requires coinsurance type for BenefitLimitRule scope" do
    scoped_cost_share = build(:cost_share, scope: create(:benefit_limit_rule), cost_share_type: :excess, unit: :amount)

    expect(scoped_cost_share).not_to be_valid
    expect(scoped_cost_share.errors[:cost_share_type]).to include("must be coinsurance for benefit and rule cost shares")
  end

  it "requires percent unit for coinsurance" do
    scoped_cost_share = build(:cost_share, scope: create(:module_benefit), cost_share_type: :coinsurance, unit: :amount)

    expect(scoped_cost_share).not_to be_valid
    expect(scoped_cost_share.errors[:unit]).to include("must be percent for coinsurance")
  end

  it "requires amount unit for deductible or excess" do
    scoped_cost_share = build(:cost_share, scope: create(:plan_module), cost_share_type: :excess, unit: :percent)

    expect(scoped_cost_share).not_to be_valid
    expect(scoped_cost_share.errors[:unit]).to include("must be amount for deductible or excess")
  end

  it "requires amount for coinsurance" do
    scoped_cost_share = build(:cost_share, scope: create(:module_benefit), cost_share_type: :coinsurance, amount: nil, unit: :percent)

    expect(scoped_cost_share).not_to be_valid
    expect(scoped_cost_share.errors[:amount]).to include("must be present for coinsurance")
  end

  it "requires at least one currency amount for deductible or excess" do
    scoped_cost_share = build(:cost_share, scope: create(:plan_module), cost_share_type: :deductible, amount_usd: nil, amount_gbp: nil, amount_eur: nil, unit: :amount)

    expect(scoped_cost_share).not_to be_valid
    expect(scoped_cost_share.errors[:base]).to include("At least one currency amount (USD, GBP, or EUR) must be specified")
  end

  it "requires cap amount when cap period is present" do
    scoped_cost_share = build(:cost_share, scope: create(:module_benefit), cost_share_type: :coinsurance, amount: 20, unit: :percent, cap_period: :per_year, cap_amount_usd: nil, cap_amount_gbp: nil, cap_amount_eur: nil)

    expect(scoped_cost_share).not_to be_valid
    expect(scoped_cost_share.errors[:base]).to include("At least one cap currency amount (USD, GBP, or EUR) must be specified")
  end

  it "requires cap period when cap amount is present" do
    scoped_cost_share = build(:cost_share, scope: create(:module_benefit), cost_share_type: :coinsurance, amount: 20, unit: :percent, cap_amount_usd: 5000, cap_period: nil)

    expect(scoped_cost_share).not_to be_valid
    expect(scoped_cost_share.errors[:cap_period]).to include("must be present when cap amount is provided")
  end

  it "includes cap wording in specification text when present" do
    scoped_cost_share = build(:cost_share, scope: create(:module_benefit), cost_share_type: :coinsurance, amount: 20, unit: :percent, per: :per_visit, cap_amount_usd: 5000, cap_period: :per_year)

    expect(scoped_cost_share.specification_text).to include("20% coinsurance (per visit)")
    expect(scoped_cost_share.specification_text).to include("capped at USD 5,000.00 per year (maximum member pays)")
  end

  it "renders multi-currency excess wording" do
    scoped_cost_share = build(:cost_share, scope: create(:plan_module), cost_share_type: :excess, amount_usd: 50, amount_gbp: 40, unit: :amount, per: :per_event)

    expect(scoped_cost_share.specification_text).to eq("USD 50.00 / GBP 40.00 excess per service")
  end

  it "uses per service wording for coinsurance when per is per_event" do
    scoped_cost_share = build(:cost_share, scope: create(:module_benefit), cost_share_type: :coinsurance, amount: 20, unit: :percent, per: :per_event)

    expect(scoped_cost_share.specification_text).to eq("20% coinsurance (per service)")
  end
end
