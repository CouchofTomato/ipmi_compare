class ModuleBenefit < ApplicationRecord
  #== Associations ===============================================
  belongs_to :plan_module
  belongs_to :benefit
  belongs_to :benefit_limit_group, optional: true
  belongs_to :base_module_benefit, class_name: "ModuleBenefit", optional: true
  has_many :enhancing_module_benefits,
           class_name: "ModuleBenefit",
           foreign_key: :base_module_benefit_id,
           dependent: :nullify

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
  validates :base_module_benefit, presence: true, if: :enhance?
  validates :base_module_benefit, absence: true, unless: :enhance?
  validate :coverage_or_limit_must_be_present
  validate :base_module_benefit_cannot_reference_self
  validate :base_module_benefit_must_be_compatible

  #== Enums ======================================================
  enum :interaction_type, {
    replace: 0,
    append: 1,
    enhance: 2
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

  def base_module_benefit_cannot_reference_self
    return if base_module_benefit_id.blank?
    return unless id.present? && base_module_benefit_id == id

    errors.add(:base_module_benefit, "cannot reference itself")
  end

  def base_module_benefit_must_be_compatible
    return if base_module_benefit.blank?

    if base_module_benefit.base_module_benefit_id.present?
      errors.add(:base_module_benefit, "must reference a base module benefit")
    end

    if benefit_id.present? && base_module_benefit.benefit_id != benefit_id
      errors.add(:base_module_benefit, "must reference the same benefit")
    end

    if plan_module.present? && base_module_benefit.plan_module.plan_version_id != plan_module.plan_version_id
      errors.add(:base_module_benefit, "must belong to the same plan version")
    end
  end
end
