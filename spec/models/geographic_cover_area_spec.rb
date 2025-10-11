require 'rails_helper'

RSpec.describe GeographicCoverArea, type: :model do
  subject(:geographic_cover_area) { create(:geographic_cover_area) }

  it { expect(geographic_cover_area).to have_many(:plan_geographic_cover_areas).dependent(:destroy) }
  it { expect(geographic_cover_area).to have_many(:plans).through(:plan_geographic_cover_areas) }

  it { expect(geographic_cover_area).to validate_presence_of :name }
  it { expect(geographic_cover_area).to validate_presence_of :code }
end
