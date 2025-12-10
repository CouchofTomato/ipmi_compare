require 'rails_helper'

RSpec.describe Benefit, type: :model do
  subject(:benefit) { create(:benefit) }

  it { expect(benefit).to belong_to(:coverage_category) }
  it { expect(benefit).to have_many(:module_benefits).dependent(:destroy) }
  it { expect(benefit).to validate_presence_of(:name) }
  it { expect(benefit).to validate_presence_of(:coverage_category) }
end
