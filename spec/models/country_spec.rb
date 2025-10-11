require 'rails_helper'

RSpec.describe Country, type: :model do
  subject(:country) { create(:country) }

  it { expect(country).to belong_to(:region) }

  it { expect(country).to have_many(:plan_residency_eligibilities).dependent(:destroy) }
  it { expect(country).to have_many(:plans).through(:plan_residency_eligibilities) }
  it { expect(country).to validate_presence_of :name }
  it { expect(country).to validate_presence_of :code }
end
