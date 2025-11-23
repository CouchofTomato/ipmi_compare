require 'rails_helper'

RSpec.describe BenefitLimitGroup, type: :model do
  subject(:benefit_limit_group) { create(:benefit_limit_group) }

  #== Associations =============================================================
  it { expect(benefit_limit_group).to belong_to(:plan_module) }
  it { expect(benefit_limit_group).to have_many(:module_benefits).dependent(:destroy) }

  #== Validations ============================================================
  it { expect(benefit_limit_group).to validate_presence_of(:name) }
  it { expect(benefit_limit_group).to validate_presence_of(:limit_unit) }

  describe 'currency limit validation' do
    context 'when all currency limits are blank' do
      it 'is invalid' do
        benefit_limit_group.limit_usd = nil
        benefit_limit_group.limit_gbp = nil
        benefit_limit_group.limit_eur = nil

        expect(benefit_limit_group).not_to be_valid
        expect(benefit_limit_group.errors[:base]).to include("At least one currency limit (USD, GBP, or EUR) must be specified")
      end
    end

    context 'when one currency limit is present' do
      it 'is valid with USD filled' do
        benefit_limit_group.limit_usd = 50_000
        benefit_limit_group.limit_gbp = nil
        benefit_limit_group.limit_eur = nil

        expect(benefit_limit_group).to be_valid
      end

      it 'is valid with GBP filled' do
        benefit_limit_group.limit_usd = nil
        benefit_limit_group.limit_gbp = 35_000
        benefit_limit_group.limit_eur = nil

        expect(benefit_limit_group).to be_valid
      end

      it 'is valid with EUR filled' do
        benefit_limit_group.limit_usd = nil
        benefit_limit_group.limit_gbp = nil
        benefit_limit_group.limit_eur = 35_000

        expect(benefit_limit_group).to be_valid
      end
    end

    context 'when two currency limits are present' do
      it 'is valid with USD and GBP filled' do
        benefit_limit_group.limit_usd = 50_000
        benefit_limit_group.limit_gbp = 35_000
        benefit_limit_group.limit_eur = nil

        expect(benefit_limit_group).to be_valid
      end

      it 'is valid with USD and EUR filled' do
        benefit_limit_group.limit_usd = 50_000
        benefit_limit_group.limit_gbp = nil
        benefit_limit_group.limit_eur = 35_000

        expect(benefit_limit_group).to be_valid
      end

      it 'is valid with GBP and EUR filled' do
        benefit_limit_group.limit_usd = nil
        benefit_limit_group.limit_gbp = 35_000
        benefit_limit_group.limit_eur = 35_000

        expect(benefit_limit_group).to be_valid
      end
    end

    context 'when all currency limits are present' do
      it 'is valid' do
        benefit_limit_group.limit_usd = 50_000
        benefit_limit_group.limit_gbp = 35_000
        benefit_limit_group.limit_eur = 35_000

        expect(benefit_limit_group).to be_valid
      end
    end
  end
end
