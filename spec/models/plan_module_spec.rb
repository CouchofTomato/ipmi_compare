require 'rails_helper'

RSpec.describe PlanModule, type: :model do
  subject(:plan_module) { create(:plan_module) }

  #== Associations ===========================================================
  it { (expect(plan_module)).to belong_to(:plan) }
  it { (expect(plan_module)).to belong_to(:module_group) }
  it { (expect(plan_module)).to have_many(:module_benefits).dependent(:destroy) }
  it { (expect(plan_module)).to have_many(:benefits).through(:module_benefits) }
  it { (expect(plan_module)).to have_and_belong_to_many(:coverage_categories) }
  it { (expect(plan_module)).to have_many(:benefit_limit_groups).dependent(:destroy) }
  it { (expect(plan_module)).to have_many(:cost_shares).dependent(:destroy) }
  it { (expect(plan_module)).to have_many(:deductibles).class_name("CostShare") }
  it { (expect(plan_module)).to have_many(:coinsurances).class_name("CostShare") }
  it { (expect(plan_module)).to have_many(:excesses).class_name("CostShare") }

  #== Validations ===========================================================
  it { (expect(plan_module)).to validate_presence_of(:name) }
end
