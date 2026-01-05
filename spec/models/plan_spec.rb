require 'rails_helper'

RSpec.describe Plan, type: :model do
  subject(:plan) { create(:plan) }

  #== Associations ===========================================================
  it { expect(plan).to belong_to :insurer }
  it { expect(plan).to have_many(:plan_versions).dependent(:destroy) }
  it { expect(plan).to have_one(:current_plan_version).dependent(:destroy) }

  #== Validations ===========================================================
  it { expect(plan).to validate_presence_of :name }

  describe "delegation to current plan version" do
    it "returns values from the current plan version" do
      version = plan.current_plan_version

      expect(plan.version_year).to eq(version.version_year)
      expect(plan.policy_type).to eq(version.policy_type)
      expect(plan.min_age).to eq(version.min_age)
      expect(plan.max_age).to eq(version.max_age)
      expect(plan.next_review_due).to eq(version.next_review_due)
    end
  end
end
