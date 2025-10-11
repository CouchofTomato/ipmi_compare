require 'rails_helper'

RSpec.describe PlanGeographicCoverArea, type: :model do
  subject(:plan_geographic_cover_area) { create(:plan_geographic_cover_area) }

  it { expect(plan_geographic_cover_area).to belong_to(:plan) }
  it { expect(plan_geographic_cover_area).to belong_to(:geographic_cover_area) }
end
