require 'rails_helper'

RSpec.describe PlanModule, type: :model do
  subject(:plan_module) { create(:plan_module) }

  it { is_expected.to belong_to(:plan) }
  it { is_expected.to belong_to(:depends_on_module).class_name('PlanModule').optional }
  it { is_expected.to belong_to(:module_group) }
  it { is_expected.to have_many(:dependent_modules).class_name('PlanModule').with_foreign_key('depends_on_module_id').dependent(:nullify) }
  it { is_expected.to have_many(:benefit_limit_groups).dependent(:destroy) }
  it { is_expected.to validate_presence_of(:name) }
end
