class BenefitLimitGroupRule < ApplicationRecord
  belongs_to :benefit_limit_group

  enum :rule_type, {
    amount: 0,
    usage: 1,
    as_charged: 2,
    not_stated: 3
  }

  enum :quantity_unit_kind, {
    session: 0,
    consultation: 1,
    visit: 2,
    day: 3,
    treatment: 4,
    other: 5
  }, prefix: :quantity_unit

  enum :period_kind, {
    policy_year: 0,
    calendar_year: 1,
    rolling_days: 2,
    rolling_months: 3,
    lifetime: 4
  }

  validates :rule_type, presence: true
  validates :period_kind, presence: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :period_value, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :quantity_value, numericality: { greater_than: 0 }, allow_nil: true

  validate :amount_requires_at_least_one_currency
  validate :non_amount_disallows_currency_amounts
  validate :usage_requires_quantity_fields
  validate :non_usage_disallows_quantity_fields
  validate :quantity_unit_custom_required_when_other
  validate :period_value_rules

  def quantity_unit_label
    return quantity_unit_custom if quantity_unit_other?
    return nil if quantity_unit_kind.blank?

    quantity_unit_kind.humanize.downcase
  end

  private

  def amount_requires_at_least_one_currency
    return unless amount?
    return if [ amount_usd, amount_gbp, amount_eur ].any?(&:present?)

    errors.add(:base, "Amount rules require at least one currency amount")
  end

  def non_amount_disallows_currency_amounts
    return if amount?
    return if [ amount_usd, amount_gbp, amount_eur ].all?(&:blank?)

    errors.add(:base, "Only amount rules can include currency values")
  end

  def usage_requires_quantity_fields
    return unless usage?

    errors.add(:quantity_value, "can't be blank") if quantity_value.blank?
    errors.add(:quantity_unit_kind, "can't be blank") if quantity_unit_kind.blank?
  end

  def non_usage_disallows_quantity_fields
    return if usage?
    return if [ quantity_value, quantity_unit_kind, quantity_unit_custom ].all?(&:blank?)

    errors.add(:base, "Only usage rules can include quantity fields")
  end

  def quantity_unit_custom_required_when_other
    return unless usage?
    return unless quantity_unit_other?
    return if quantity_unit_custom.present?

    errors.add(:quantity_unit_custom, "can't be blank when unit is other")
  end

  def period_value_rules
    if rolling_days? || rolling_months?
      errors.add(:period_value, "can't be blank") if period_value.blank?
      return
    end

    return if period_value.blank?

    errors.add(:period_value, "must be blank unless period is rolling")
  end
end
