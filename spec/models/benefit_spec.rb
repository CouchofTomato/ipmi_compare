require 'rails_helper'

RSpec.describe Benefit, type: :model do
  subject(:benefit) { create(:benefit) }

  it { expect(benefit).to validate_presence_of(:name) }
  it { expect(benefit).to validate_presence_of(:category) }
  it { expect(benefit).to define_enum_for(:category).with_values(inpatient: 0, outpatient: 1, therapies: 2, maternity: 3, dental: 4, optical: 5, medicines: 6, evacuation: 7, repatriation: 8, wellness: 9) }
end
