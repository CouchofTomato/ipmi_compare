require 'rails_helper'

RSpec.describe CostShareLink, type: :model do
  subject(:cost_share_link) { create(:cost_share_link) }

  #== Validations ==============================================================
  it { is_expected.to validate_presence_of(:cost_share) }
  it { is_expected.to validate_presence_of(:linked_cost_share) }
  it { is_expected.to validate_presence_of(:relationship_type) }

  describe "cannot_link_to_self" do
    it "validates that cost_share and linked_cost_share are not the same" do
      cost_share = create(:cost_share)
      cost_share_link = build(:cost_share_link, cost_share: cost_share, linked_cost_share: cost_share)
      expect(cost_share_link).not_to be_valid
      expect(cost_share_link.errors[:linked_cost_share]).to include("cannot be the same as cost_share")
    end
  end

  #== Associations ===========================================================
  it { is_expected.to belong_to(:cost_share) }
  it { is_expected.to belong_to(:linked_cost_share).class_name("CostShare") }

  #== Enums ===================================================================
  it { expect(cost_share_link).to define_enum_for(:relationship_type).with_values(shared_pool: 0, override: 1, dependent: 2) }
end
