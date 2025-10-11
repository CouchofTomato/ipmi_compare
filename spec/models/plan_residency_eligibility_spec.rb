require 'rails_helper'

RSpec.describe PlanResidencyEligibility, type: :model do
  subject (:plan_residency_eligibility) { create(:plan_residency_eligibility) }

  it { expect(plan_residency_eligibility).to belong_to(:plan) }
  it { expect(plan_residency_eligibility).to belong_to(:country) }
end
