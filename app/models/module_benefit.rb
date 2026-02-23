class ModuleBenefit < ApplicationRecord
  #== Associations ===============================================
  belongs_to :plan_module
  belongs_to :benefit
  belongs_to :benefit_limit_group, optional: true

  # ModuleBenefit does not store numeric limits.
  # All numeric limits are represented via BenefitLimitRule.
  has_many :benefit_limit_rules, -> { order(:scope, :position, :created_at) }, dependent: :destroy
  has_many :cost_shares, as: :scope, dependent: :destroy
  has_many :deductibles, -> { where(cost_share_type: :deductible) },
           class_name: "CostShare", as: :scope
  has_many :coinsurances, -> { where(cost_share_type: :coinsurance) },
           class_name: "CostShare", as: :scope
  has_many :excesses, -> { where(cost_share_type: :excess) },
           class_name: "CostShare", as: :scope

  accepts_nested_attributes_for :benefit_limit_rules, allow_destroy: true, reject_if: :blank_benefit_limit_rule_attributes?

  #== Validations ================================================
  validates :benefit, presence: true
  validates :plan_module, presence: true
  validates :weighting, numericality: { only_integer: true }
  validate :coverage_or_limit_must_be_present

  #== Enums ======================================================
  enum :interaction_type, {
    replace: 0,
    append: 1
  }

  delegate :coverage_category, to: :benefit

  private

  def blank_benefit_limit_rule_attributes?(attributes)
    return false if ActiveModel::Type::Boolean.new.cast(attributes["_destroy"])
    return false if attributes["scope"].present? || attributes["limit_type"].present?

    attributes["name"].blank? &&
      attributes["insurer_amount_usd"].blank? &&
      attributes["insurer_amount_gbp"].blank? &&
      attributes["insurer_amount_eur"].blank? &&
      attributes["unit"].blank? &&
      attributes["cap_insurer_amount_usd"].blank? &&
      attributes["cap_insurer_amount_gbp"].blank? &&
      attributes["cap_insurer_amount_eur"].blank? &&
      attributes["cap_unit"].blank? &&
      attributes["notes"].blank?
  end

  def coverage_or_limit_must_be_present
    if coverage_description.blank? && benefit_limit_rules.reject(&:marked_for_destruction?).blank?
      errors.add(:base, "Either a coverage description or at least one benefit limit rule must be present")
    end
  end
end
