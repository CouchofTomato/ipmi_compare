require 'rails_helper'

RSpec.describe Plan, type: :model do
  subject(:plan) { create(:plan) }

  #== Associations ===========================================================
  it { expect(plan).to belong_to :insurer }
  it { expect(plan).to have_many(:plan_geographic_cover_areas).dependent(:destroy) }
  it { expect(plan).to have_many(:geographic_cover_areas).through(:plan_geographic_cover_areas) }
  it { expect(plan).to have_many(:plan_residency_eligibilities).dependent(:destroy) }
  it { expect(plan).to have_many(:cost_shares).dependent(:destroy) }
  it { expect(plan).to have_many(:deductibles).class_name("CostShare") }
  it { expect(plan).to have_many(:coinsurances).class_name("CostShare") }
  it { expect(plan).to have_many(:excesses).class_name("CostShare") }

  #== Validations ===========================================================
  it { expect(plan).to validate_presence_of :name }
  it { expect(plan).to validate_presence_of :min_age }
  it { expect(plan).to validate_numericality_of(:min_age).is_greater_than_or_equal_to(0).only_integer }
  it { expect(plan).to validate_numericality_of(:max_age).is_greater_than_or_equal_to(0).only_integer.allow_nil }
  it { expect(plan).to validate_presence_of :version_year }
  it { expect(plan).to validate_presence_of :policy_type }
  it { expect(plan).to validate_presence_of :next_review_due  }

  #== Enums ===================================================================
  it { should define_enum_for(:policy_type).with_values(individual: 0, company: 1, corporate: 2) }
end
