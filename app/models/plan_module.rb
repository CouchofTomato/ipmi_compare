class PlanModule < ApplicationRecord
  belongs_to :plan_version
  belongs_to :module_group
  delegate :plan, to: :plan_version

  has_many :module_benefits, dependent: :destroy
  has_many :benefits, through: :module_benefits

  has_and_belongs_to_many :coverage_categories

  has_many :benefit_limit_groups, dependent: :destroy

  has_many :cost_shares, as: :scope, dependent: :destroy
  has_many :deductibles, -> { where(cost_share_type: :deductible) },
           class_name: "CostShare", as: :scope
  has_many :coinsurances, -> { where(cost_share_type: :coinsurance) },
           class_name: "CostShare", as: :scope
  has_many :excesses, -> { where(cost_share_type: :excess) },
           class_name: "CostShare", as: :scope

  validates :name, presence: true
  before_validation :apply_plan_version_from_group
  validates :plan_version_id, presence: true
  validate :module_group_matches_plan_version

  private

  def apply_plan_version_from_group
    return if plan_version_id_changed? && plan_version_id.nil?

    self.plan_version ||= module_group&.plan_version
  end

  def module_group_matches_plan_version
    return if module_group.blank? || plan_version.blank?

    if module_group.plan_version_id != plan_version_id
      errors.add(:module_group, "must belong to the same plan version")
    end
  end
end
