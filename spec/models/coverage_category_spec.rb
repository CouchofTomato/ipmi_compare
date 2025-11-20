require 'rails_helper'

RSpec.describe CoverageCategory, type: :model do
  subject { create(:coverage_category) }

  #== Associations ===========================================================

  it { should have_and_belong_to_many(:plan_modules) }
end
