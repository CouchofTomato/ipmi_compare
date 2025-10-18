require 'rails_helper'

RSpec.describe CostShare, type: :model do
  subject(:cost_share) { create(:cost_share) }

  #== Associations ===========================================================
  it { expect(cost_share).to belong_to(:linked_cost_share).class_name('CostShare').optional }

  #== Enums ===================================================================
  it { expect(cost_share).to define_enum_for(:cost_share_type).with_values(deductible: 0, excess: 1, coinsurance: 2) }
  it { expect(cost_share).to define_enum_for(:unit).with_values(amount: 0, percent: 1) }
  it { expect(cost_share).to define_enum_for(:per).with_values(per_visit: 0, per_condition: 1, per_year: 2) }

  # == Validations =============================================================
  it { expect(cost_share).to validate_presence_of(:scope) }
  it { expect(cost_share).to validate_presence_of(:cost_share_type) }
  it { expect(cost_share).to validate_presence_of(:unit) }
  it { expect(cost_share).to validate_presence_of(:per) }
end
