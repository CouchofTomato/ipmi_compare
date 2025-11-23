require 'rails_helper'

RSpec.describe User, type: :model do
  subject(:user) { create(:user) }

  #== Associations ===============================
  it { should have_many(:wizard_progresses) }
end
