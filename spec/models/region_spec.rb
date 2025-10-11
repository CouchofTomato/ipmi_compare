require 'rails_helper'

RSpec.describe Region, type: :model do
  subject(:region) { create(:region) }

  it { expect(region).to validate_presence_of :name }
  it { expect(region).to validate_presence_of :code }
end
