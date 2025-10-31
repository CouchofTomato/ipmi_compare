require 'rails_helper'

RSpec.describe PlanResidencyEligibility, type: :model do
  subject (:plan_residency_eligibility) { create(:plan_residency_eligibility) }

  #== Associations ===========================================================
  it { expect(plan_residency_eligibility).to belong_to(:plan) }

  #== Validations ===========================================================
  it { expect(plan_residency_eligibility).to validate_presence_of(:country_code) }
  it { expect(plan_residency_eligibility).to validate_inclusion_of(:country_code).in_array(ISO3166::Country.all.map(&:alpha2)) }
end
