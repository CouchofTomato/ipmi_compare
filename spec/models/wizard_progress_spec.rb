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

  describe "#plan_version" do
    it "returns the version stored in metadata when present" do
      plan = create(:plan)
      draft_version = PlanVersionDuplicator.call(plan.current_plan_version)
      progress = create(:wizard_progress, wizard_type: "plan_creation", subject: plan, metadata: { "plan_version_id" => draft_version.id })

      expect(progress.plan_version).to eq(draft_version)
    end

    it "falls back to the current plan version when metadata is missing" do
      plan = create(:plan)
      progress = create(:wizard_progress, wizard_type: "plan_creation", subject: plan, metadata: {})

      expect(progress.plan_version).to eq(plan.current_plan_version)
    end
  end

  describe "comparison selection helpers" do
    let(:plan) { create(:plan) }
    let(:group) { create(:module_group, plan_version: plan.current_plan_version) }
    let(:module_a) { create(:plan_module, plan_version: plan.current_plan_version, module_group: group) }
    let(:module_b) { create(:plan_module, plan_version: plan.current_plan_version, module_group: group) }

    let(:progress) do
      create(
        :wizard_progress,
        :plan_comparison,
        state: {
          "plan_selections" => {
            "legacy" => { "plan_id" => plan.id, "module_groups" => { group.id.to_s => module_a.id } },
            "new" => { "id" => "abc", "plan_id" => plan.id, "module_groups" => { group.id.to_s => module_b.id } }
          }
        }
      )
    end

    it "normalizes plan selections for plan comparison progress" do
      selections = progress.comparison_plan_selections

      expect(selections.size).to eq(2)
      expect(selections.all? { |sel| sel["id"].present? }).to eq(true)
      expect(selections.first["module_groups"]).to eq(group.id.to_s => module_a.id)
    end

    it "returns selected module ids grouped by plan id" do
      result = progress.comparison_selected_module_ids_by_plan

      expect(result[plan.id]).to contain_exactly(module_a.id, module_b.id)
    end
  end
end
