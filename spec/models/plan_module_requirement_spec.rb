require 'rails_helper'

RSpec.describe PlanModuleRequirement, type: :model do
  subject(:requirement) { create(:plan_module_requirement, plan: plan, dependent_module: dependent_module, required_module: required_module) }
  let(:plan) { create(:plan) }
  let(:dependent_module) { create(:plan_module, plan: plan) }
  let(:required_module) { create(:plan_module, plan: plan) }

  #== Associations ===========================================================
  describe 'associations' do
    it { is_expected.to belong_to(:plan) }
    it { is_expected.to belong_to(:dependent_module).class_name('PlanModule') }
    it { is_expected.to belong_to(:required_module).class_name('PlanModule') }
  end

    #== Validations ===========================================================
    it { is_expected.to validate_presence_of(:plan_id) }
    it { is_expected.to validate_presence_of(:dependent_module_id) }
    it { is_expected.to validate_presence_of(:required_module_id) }
  describe 'modules_belong_to_plan' do
    context 'when the dependent module does not have the same plan as the plan module requirement' do
      subject(:requirement) { build(:plan_module_requirement, plan: plan, dependent_module: dependent_module, required_module: required_module) }
      let(:plan) { create(:plan) }
      let(:dependent_module) { create(:plan_module, plan: dependent_module_plan) }
      let(:dependent_module_plan) { create(:plan) }
      let(:required_module) { create(:plan_module, plan: plan) }

      it 'is invalid' do
        requirement.validate
        expect(requirement).not_to be_valid
      end

      it 'logs the appropriate error' do
        requirement.validate
        expect(requirement.errors[:base]).to include("Dependent and required modules must belong to the same plan")
      end
    end

    context 'when the required module does not have the same plan as the plan module requirement' do
      subject(:requirement) { build(:plan_module_requirement, plan: plan, dependent_module: required_module) }
      let(:plan) { create(:plan) }
      let(:required_module) { create(:plan_module, plan: required_module_plan) }
      let(:required_module_plan) { create(:plan) }

      it 'is invalid' do
        requirement.validate
        expect(requirement).not_to be_valid
      end

      it 'logs the appropriate error' do
        requirement.validate
        expect(requirement.errors[:base]).to include("Dependent and required modules must belong to the same plan")
      end
    end

    context 'when both modules belong to the same plan as the plan module requirement' do
      subject(:requirement) { build(:plan_module_requirement, plan: plan, dependent_module: dependent_module, required_module: required_module) }
      let(:plan) { create(:plan) }
      let(:dependent_module) { create(:plan_module, plan: plan) }
      let(:required_module) { create(:plan_module, plan: plan) }

      it 'is valid' do
        requirement.validate
        expect(requirement).to be_valid
      end
    end
  end

  describe 'not self referencing' do
    context 'when the dependent module is the same as the required module' do
      subject(:requirement) { build(:plan_module_requirement, plan: plan, dependent_module: same_module, required_module: same_module) }
      let(:plan) { create(:plan) }
      let(:same_module) { create(:plan_module, plan: plan) }

      it 'is invalid' do
        requirement.validate
        expect(requirement).not_to be_valid
      end

      it 'logs the appropriate error message' do
        requirement.validate
        expect(requirement.errors[:required_module_id]).to include("cannot be the same as the dependent module")
      end
    end

    context 'when the dependent module is different from the required module' do
      subject(:requirement) { build(:plan_module_requirement, plan: plan, dependent_module: dependent_module, required_module: required_module) }
      let(:dependent_module) { create(:plan_module, plan: plan) }
      let(:required_module) { create(:plan_module, plan: plan) }

      it 'is valid' do
        requirement.validate
        expect(requirement).to be_valid
      end
    end
  end

  describe 'no reverse cycle' do
    context 'when the required module requires the dependent module and the dependent module requires the required module' do
      before do
        create(:plan_module_requirement,
              plan: plan,
              dependent_module: dependent_module,
              required_module: required_module)
      end

      subject(:requirement) { build(:plan_module_requirement, plan: plan, dependent_module: required_module, required_module: dependent_module) }
      let(:dependent_module) { create(:plan_module, plan: plan) }
      let(:required_module) { create(:plan_module, plan: plan) }

      it 'is invalid' do
        requirement.validate
        expect(requirement).not_to be_valid
      end

      it 'logs the appropriate error message' do
        requirement.validate
        expect(requirement.errors[:base]).to include("Circular dependency detected")
      end
    end
  end
end
