require 'rails_helper'

RSpec.describe ModuleGroup, type: :model do
  subject(:module_group) { create(:module_group) }

  it { expect(module_group).to validate_presence_of(:name) }
end
