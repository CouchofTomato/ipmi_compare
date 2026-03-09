class BenefitLimitGroup < ApplicationRecord
  belongs_to :plan_module

  has_many :module_benefits, dependent: :destroy
  has_many :benefit_limit_group_rules, -> { order(:position, :created_at) }, dependent: :destroy

  has_many :cost_shares, as: :scope, dependent: :destroy
  has_many :deductibles, -> { where(cost_share_type: :deductible) },
            class_name: "CostShare", as: :scope
  has_many :coinsurances, -> { where(cost_share_type: :coinsurance) },
            class_name: "CostShare", as: :scope
  has_many :excesses, -> { where(cost_share_type: :excess) },
            class_name: "CostShare", as: :scope

  accepts_nested_attributes_for :benefit_limit_group_rules, allow_destroy: true

  validates :name, presence: true
  validate :at_least_one_rule_or_legacy_limit_present

  def primary_rule
    benefit_limit_group_rules.first
  end

  private

  def at_least_one_rule_or_legacy_limit_present
    return if benefit_limit_group_rules.reject(&:marked_for_destruction?).any?
    return if [ limit_usd, limit_gbp, limit_eur ].any?(&:present?) && limit_unit.present?

    errors.add(:base, "Add at least one shared limit rule")
  end
end
