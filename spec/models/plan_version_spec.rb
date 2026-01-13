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
  it { expect(plan_version).to validate_presence_of :effective_on }
  it { expect(plan_version).to validate_numericality_of(:min_age).is_greater_than_or_equal_to(0).only_integer.allow_nil }
  it { expect(plan_version).to validate_numericality_of(:max_age).is_greater_than_or_equal_to(0).only_integer.allow_nil }
  it { expect(plan_version).to validate_inclusion_of(:children_only_allowed).in_array([ true, false ]) }
  it { expect(plan_version).to validate_inclusion_of(:published).in_array([ true, false ]) }
  it { expect(plan_version).to validate_presence_of :policy_type }
  it { expect(plan_version).to validate_presence_of :next_review_due }

  #== Enums ===================================================================
  it { should define_enum_for(:policy_type).with_values(individual: 0, company: 1, corporate: 2) }

  describe "effective date rules" do
    let(:plan) { create(:plan, published: true, version_year: 2024, effective_on: Date.new(2024, 1, 1)) }

    before do
      plan.current_plan_version.update!(published: true, effective_on: Date.new(2024, 1, 1), version_year: 2024)
    end

    it "requires effective_through to be on or after effective_on" do
      version = build(
        :plan_version,
        effective_on: Date.new(2025, 1, 2),
        effective_through: Date.new(2025, 1, 1)
      )

      expect(version).not_to be_valid
      expect(version.errors[:effective_through]).to include("must be on or after effective on")
    end

    it "rejects overlapping published versions for a plan" do
      overlapping =
        plan.plan_versions.build(
          version_year: 2025,
          effective_on: Date.new(2024, 6, 1),
          effective_through: nil,
          min_age: 0,
          max_age: 65,
          children_only_allowed: false,
          published: true,
          policy_type: :company,
          last_reviewed_at: Date.new(2025, 10, 6),
          next_review_due: Date.new(2025, 10, 6),
          review_notes: "Overlap",
          current: false
        )

      expect(overlapping).not_to be_valid
      expect(overlapping.errors[:base]).to include("Effective dates overlap another published version")
    end

    it "allows overlapping drafts" do
      overlapping =
        plan.plan_versions.build(
          version_year: 2025,
          effective_on: Date.new(2024, 6, 1),
          effective_through: nil,
          min_age: 0,
          max_age: 65,
          children_only_allowed: false,
          published: false,
          policy_type: :company,
          last_reviewed_at: Date.new(2025, 10, 6),
          next_review_due: Date.new(2025, 10, 6),
          review_notes: "Draft overlap",
          current: false
        )

      expect(overlapping).to be_valid
    end
  end
end
