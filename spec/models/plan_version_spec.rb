require "rails_helper"

RSpec.describe PlanVersion, type: :model do
  subject(:plan_version) { create(:plan_version) }

  #== Associations ===========================================================
  it { expect(plan_version).to belong_to :plan }
  it { expect(plan_version).to have_many(:plan_geographic_cover_areas).dependent(:destroy) }
  it { expect(plan_version).to have_many(:geographic_cover_areas).through(:plan_geographic_cover_areas) }
  it { expect(plan_version).to have_many(:plan_residency_eligibilities).dependent(:destroy) }
  it { expect(plan_version).to have_many(:module_groups).dependent(:destroy) }
  it { expect(plan_version).to have_many(:plan_modules).dependent(:destroy) }
  it { expect(plan_version).to have_many(:plan_module_requirements).dependent(:destroy) }
  it { expect(plan_version).to have_many(:cost_shares).dependent(:destroy) }

  #== Validations ===========================================================
  it { expect(plan_version).to validate_presence_of :version_year }
  it { expect(plan_version).to validate_numericality_of(:min_age).is_greater_than_or_equal_to(0).only_integer.allow_nil }
  it { expect(plan_version).to validate_numericality_of(:max_age).is_greater_than_or_equal_to(0).only_integer.allow_nil }
  it { expect(plan_version).to validate_inclusion_of(:children_only_allowed).in_array([ true, false ]) }
  it { expect(plan_version).to validate_inclusion_of(:published).in_array([ true, false ]) }
  it { expect(plan_version).to validate_presence_of :policy_type }
  it { expect(plan_version).to validate_presence_of :next_review_due }

  #== Enums ===================================================================
  it { should define_enum_for(:policy_type).with_values(individual: 0, company: 1, corporate: 2) }
end
