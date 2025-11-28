require 'rails_helper'

RSpec.describe WizardProgress, type: :model do
  subject(:wizard_progress) { create(:wizard_progress) }

  #== Associations ===========================================================
  it { expect(wizard_progress).to belong_to(:subject).optional(true) }
  it { expect(wizard_progress).to belong_to(:user) }
  it { expect(wizard_progress).to belong_to(:last_actor).class_name("User").optional }

  #== Validations ============================================================
  it { expect(wizard_progress).to validate_presence_of(:wizard_type) }
  it { expect(wizard_progress).to validate_presence_of(:current_step) }
  it { expect(wizard_progress).to validate_presence_of(:started_at) }
  it { expect(wizard_progress).to validate_presence_of(:step_order) }
  it { expect(wizard_progress).to validate_numericality_of(:step_order).is_greater_than_or_equal_to(0).only_integer }
  describe "wizard type uniqueness scoped to subject" do
    it "allows duplicates when subject is nil" do
      create(:wizard_progress, wizard_type: "plan_creation", subject: nil, subject_type: nil, subject_id: nil)

      duplicate = build(
        :wizard_progress,
        wizard_type: "plan_creation",
        subject: nil,
        subject_type: nil,
        subject_id: nil
      )

      expect(duplicate).to be_valid
    end

    it "prevents duplicates when subject is present" do
      plan = create(:plan)
      user = create(:user)
      create(:wizard_progress, wizard_type: "plan_creation", subject: plan, user:)

      duplicate = build(:wizard_progress, wizard_type: "plan_creation", subject: plan, user:)
      expect(duplicate).to be_invalid
      expect(duplicate.errors[:wizard_type]).to include("has already been taken")
    end
  end

  #== Enums ===================================================================
  it { expect(wizard_progress).to define_enum_for(:status).with_values(in_progress: "in_progress", complete: "complete", abandoned: "abandoned", expired: "expired").backed_by_column_of_type(:string) }

  describe "#flow" do
    subject(:wizard_progress) { build(:wizard_progress, wizard_type: "plan_creation", current_step: "plan_residency") }

    it "returns the next step correctly" do
      expect(wizard_progress.next_step).to eq("geographic_cover_areas")
    end

    it "returns the previous step correctly" do
      wizard_progress.current_step = "geographic_cover_areas"
      expect(wizard_progress.previous_step).to eq("plan_residency")
    end
    it "calculates progress as a percentage" do
      expect(wizard_progress.progress).to be_between(0, 100)
    end
  end
end
