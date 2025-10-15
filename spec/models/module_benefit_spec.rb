require 'rails_helper'

RSpec.describe ModuleBenefit, type: :model do
  subject(:module_benefit) { create(:module_benefit) }

  it { expect(module_benefit).to belong_to(:plan_module) }
  it { expect(module_benefit).to belong_to(:benefit) }
  it { expect(module_benefit).to belong_to(:benefit_limit_group).optional(true) }

  describe 'coverage_or_limit_must_be_present' do
    context 'when no coverage description or limits are provided' do
      it 'is invalid' do
        module_benefit = build(:module_benefit,
          coverage_description: nil,
          limit_usd: nil,
          limit_gbp: nil,
          limit_eur: nil
        )
        expect(module_benefit).not_to be_valid
        expect(module_benefit.errors[:base]).to include(
          "Either a coverage description or at least one limit must be present"
        )
      end
    end

    context 'when coverage description is provided' do
      it 'is valid without limits' do
        module_benefit = build(:module_benefit,
          coverage_description: "Full refund",
          limit_usd: nil
        )
        expect(module_benefit).to be_valid
      end
    end

    context 'when a monetary limit is provided' do
      it 'is valid without a coverage description' do
        module_benefit = build(:module_benefit,
          coverage_description: nil,
          limit_usd: 5000.00,
          limit_unit: "per year"
        )
        expect(module_benefit).to be_valid
      end
    end

    context 'when both coverage description and limits are provided' do
      it 'is valid' do
        module_benefit = build(:module_benefit,
          coverage_description: "Full refund up to module limit",
          limit_usd: 5000.00,
          limit_unit: "per year"
        )
        expect(module_benefit).to be_valid
      end
    end
  end
end
