require 'rails_helper'

RSpec.describe CoverageCategory, type: :model do
  subject { create(:coverage_category) }

  #== Associations ===========================================================

  it { should have_and_belong_to_many(:plan_modules) }
  it { should have_many(:module_benefits) }

  #== Validations =============================================================

  it { should validate_presence_of(:name) }
  it { should validate_uniqueness_of(:name) }
  it { should validate_presence_of(:position) }
end
