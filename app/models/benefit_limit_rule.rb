class BenefitLimitRule < ApplicationRecord
  belongs_to :module_benefit

  enum :scope, {
    benefit_level: 0,
    itemised: 1
  }

  enum :limit_type, {
    amount: 0,
    as_charged: 1,
    not_stated: 2
  }

  validates :scope, presence: true
  validates :limit_type, presence: true
  validates :name, presence: true, if: :itemised?
  validate :amount_requires_at_least_one_currency
  validate :amount_requires_unit
  validate :non_amount_disallows_insurer_amount_and_unit
  validate :not_stated_disallows_caps
  validate :cap_unit_required_when_cap_present

  private

  def amount_requires_at_least_one_currency
    return unless amount?
    return if [ insurer_amount_usd, insurer_amount_gbp, insurer_amount_eur ].any?(&:present?)

    errors.add(:base, "Amount limit rules require at least one currency amount")
  end

  def amount_requires_unit
    return unless amount?
    return if unit.present?

    errors.add(:unit, "can't be blank")
  end

  def non_amount_disallows_insurer_amount_and_unit
    return if amount?
    return if [
      insurer_amount_usd,
      insurer_amount_gbp,
      insurer_amount_eur,
      unit
    ].all?(&:blank?)

    errors.add(:base, "As charged and not stated rules cannot include insurer amount or unit")
  end

  def cap_unit_required_when_cap_present
    return unless [ cap_insurer_amount_usd, cap_insurer_amount_gbp, cap_insurer_amount_eur ].any?(&:present?)
    return if cap_unit.present?

    errors.add(:cap_unit, "can't be blank when a cap amount is provided")
  end

  def not_stated_disallows_caps
    return unless not_stated?
    return if [ cap_insurer_amount_usd, cap_insurer_amount_gbp, cap_insurer_amount_eur, cap_unit ].all?(&:blank?)

    errors.add(:base, "Not stated rules cannot include cap values")
  end
end
