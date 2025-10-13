require 'rails_helper'

RSpec.describe Plan, type: :model do
  subject(:plan) { create(:plan) }

  it { expect(plan).to belong_to :insurer }
  it { expect(plan).to have_many(:plan_geographic_cover_areas).dependent(:destroy) }
  it { expect(plan).to have_many(:geographic_cover_areas).through(:plan_geographic_cover_areas) }
  it { expect(plan).to have_many(:plan_residency_eligibilities).dependent(:destroy) }
  it { expect(plan).to have_many(:countries).through(:plan_residency_eligibilities) }

  it { expect(plan).to validate_presence_of :name }
  it { expect(plan).to validate_presence_of :min_age }
  it { expect(plan).to validate_numericality_of(:min_age).is_greater_than_or_equal_to(0).only_integer }
  it { expect(plan).to validate_numericality_of(:max_age).is_greater_than_or_equal_to(0).only_integer.allow_nil }
  it { expect(plan).to validate_presence_of :version_year }
  it { expect(plan).to validate_presence_of :policy_type }
  it { expect(plan).to validate_presence_of :next_review_due  }
  it { should define_enum_for(:policy_type).with_values(individual: 0, company: 1, corporate: 2) }

  describe "overall_limit_presence_rule" do
    it "is valid when marked unlimited with no numeric limits" do
      plan = build(:plan, :unlimited)
      expect(plan).to be_valid
    end

    it "is invalid when not unlimited and no numeric limits are provided" do
      plan = build(:plan, overall_limit_unlimited: false, overall_limit_usd: nil, overall_limit_gbp: nil, overall_limit_eur: nil)
      expect(plan).not_to be_valid
      expect(plan.errors[:base]).to include("Specify at least one overall limit or mark the plan as unlimited")
    end

    it "is valid when at least one numeric limit is present" do
      plan = build(:plan, overall_limit_unlimited: false, overall_limit_usd: 5_000_000)
      expect(plan).to be_valid
    end
  end
end
