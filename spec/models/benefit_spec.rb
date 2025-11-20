require 'rails_helper'

RSpec.describe Benefit, type: :model do
  subject(:benefit) { create(:benefit) }

  it { expect(benefit).to validate_presence_of(:name) }
  it { expect(benefit).to validate_presence_of(:category) }
end
