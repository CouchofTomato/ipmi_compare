require 'rails_helper'

RSpec.describe ModuleGroup, type: :model do
  subject(:module_group) { create(:module_group) }

  #== Associations ===========================================================
  it { expect(module_group).to belong_to(:plan_version) }
  it { expect(module_group).to have_many(:plan_modules).dependent(:destroy) }

  #== Validations ===========================================================
  it { expect(module_group).to validate_presence_of(:name) }
end
