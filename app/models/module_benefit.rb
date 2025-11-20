class ModuleBenefit < ApplicationRecord
  #== Associations ===============================================
  belongs_to :plan_module
  belongs_to :benefit
  belongs_to :coverage_category
  belongs_to :benefit_limit_group, optional: true

  has_many :cost_shares, as: :scope, dependent: :destroy
  has_many :deductibles, -> { where(cost_share_type: :deductible) },
           class_name: "CostShare", as: :scope
  has_many :coinsurances, -> { where(cost_share_type: :coinsurance) },
           class_name: "CostShare", as: :scope
  has_many :excesses, -> { where(cost_share_type: :excess) },
           class_name: "CostShare", as: :scope

  #== Validations ================================================
  validates :coverage_category, presence: true
  validates :benefit, presence: true
  validates :plan_module, presence: true
  validates :weighting, numericality: { only_integer: true }
  validate :coverage_or_limit_must_be_present

  #== Enums ======================================================
  enum :interaction_type, {
    replace: 0,
    append: 1
  }

  private

  def coverage_or_limit_must_be_present
    if [ coverage_description, limit_usd, limit_gbp, limit_eur ].all?(&:blank?)
      errors.add(:base, "Either a coverage description or at least one limit must be present")
    end
  end
end
