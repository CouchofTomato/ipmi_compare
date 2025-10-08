require 'rails_helper'

RSpec.describe Plan, type: :model do
  subject(:plan) { create(:plan) }

  it { expect(plan).to validate_presence_of :name }
  it { expect(plan).to validate_presence_of :min_age }
  it { expect(plan).to validate_numericality_of(:min_age).is_greater_than_or_equal_to(0).only_integer }
  it { expect(plan).to validate_numericality_of(:max_age).is_greater_than_or_equal_to(0).only_integer.allow_nil }
  it { expect(plan).to validate_presence_of :version_year }
  it { expect(plan).to validate_presence_of :policy_type }
  it { expect(plan).to validate_presence_of :next_review_due  }
  it { expect(plan).to belong_to :insurer }
end
