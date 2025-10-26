require 'rails_helper'

RSpec.describe WizardProgress, type: :model do
  subject(:wizard_progress) { create(:wizard_progress) }

  #== Associations ===========================================================
  it { expect(wizard_progress).to belong_to(:entity) }
  it { expect(wizard_progress).to belong_to(:last_actor).class_name("User").optional }

  #== Validations ============================================================
  it { expect(wizard_progress).to validate_presence_of(:wizard_type) }
  it { expect(wizard_progress).to validate_presence_of(:current_step) }
  it { expect(wizard_progress).to validate_presence_of(:started_at) }
  it { expect(wizard_progress).to validate_presence_of(:step_order) }
  it { expect(wizard_progress).to validate_numericality_of(:step_order).is_greater_than_or_equal_to(0).only_integer }
  it { expect(wizard_progress).to validate_uniqueness_of(:wizard_type).scoped_to(:entity_type, :entity_id) }

  #== Enums ===================================================================
  it { expect(wizard_progress).to define_enum_for(:status).with_values(in_progress: "in_progress", complete: "complete", abandoned: "abandoned", expired: "expired").backed_by_column_of_type(:string) }
end
