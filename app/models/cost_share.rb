class CostShare < ApplicationRecord
  include ActiveSupport::NumberHelper

  # Virtual attributes used only for the wizard form selections
  attr_accessor :applies_to, :plan_module_id, :module_benefit_id, :benefit_limit_group_id, :benefit_limit_rule_ids

  # Scope can be a PlanVersion, PlanModule, ModuleBenefit, BenefitLimitGroup, or BenefitLimitRule
  belongs_to :scope, polymorphic: true

  has_many :cost_share_links, dependent: :destroy
  has_many :linked_cost_shares,
           through: :cost_share_links,
           source: :linked_cost_share

  # Reverse links where this cost share is the "linked" one
  has_many :reverse_cost_share_links,
           class_name: "CostShareLink",
           foreign_key: :linked_cost_share_id,
           dependent: :destroy

  has_many :parent_cost_shares,
           through: :reverse_cost_share_links,
           source: :cost_share

  enum :cost_share_type, {
    deductible: 0,
    excess: 1,
    coinsurance: 2
  }

  enum :kind, {
    deductible: 0,
    coinsurance: 1
  }, prefix: :kind

  enum :unit, {
    amount: 0,
    percent: 1
  }

  enum :per, {
    per_visit: 0,
    per_condition: 1,
    per_year: 2,
    per_event: 3
  }

  enum :cap_period, {
    per_year: 0,
    per_condition: 1,
    per_admission: 2
  }, prefix: :cap

  validates :scope, presence: true
  validates :scope_type, inclusion: { in: %w[PlanVersion PlanModule ModuleBenefit BenefitLimitGroup BenefitLimitRule] }, allow_blank: true
  validates :kind, presence: true
  validates :cost_share_type, presence: true
  validates :unit, presence: true
  validates :per, presence: true

  before_validation :assign_kind_from_cost_share_type
  validate :cost_share_type_matches_scope
  validate :kind_family_alignment
  validate :unit_matches_cost_share_type
  validate :coinsurance_requires_percent_amount
  validate :money_types_require_at_least_one_currency_amount
  validate :member_cap_pairing

  def member_cap?
    cap_amount_values.any? && cap_period.present?
  end

  def specification_text
    base_text = case cost_share_type
    when "coinsurance"
      "#{format_percentage(amount)} coinsurance (#{per_label})"
    when "excess"
      excess_text
    else
      "#{format_money_values(amount_values)} deductible (#{per_label})"
    end

    return base_text unless member_cap?

    "#{base_text}, capped at #{format_money_values(cap_amount_values)} #{cap_period_label} (maximum member pays)"
  end

  private

  def amount_values
    {
      "USD" => amount_usd,
      "GBP" => amount_gbp,
      "EUR" => amount_eur
    }.compact_blank
  end

  def cap_amount_values
    {
      "USD" => cap_amount_usd,
      "GBP" => cap_amount_gbp,
      "EUR" => cap_amount_eur
    }.compact_blank
  end

  def per_label
    return "per service" if per_event?

    per.to_s.tr("_", " ")
  end

  def cap_period_label
    cap_period.to_s.tr("_", " ")
  end

  def excess_text
    return "#{format_money_values(amount_values)} excess per service" if per_event?

    "#{format_money_values(amount_values)} excess (#{per_label})"
  end

  def format_percentage(value)
    integer_value = value.to_d
    return "#{integer_value.to_i}%" if integer_value.frac.zero?

    "#{format('%.2f', integer_value)}%"
  end

  def format_money_values(values)
    values.map do |currency_code, value|
      "#{currency_code} #{number_to_currency(value.to_d, unit: '', precision: 2)}"
    end.join(" / ")
  end

  def assign_kind_from_cost_share_type
    return if cost_share_type.blank?

    self.kind =
      case cost_share_type.to_s
      when "coinsurance"
        :coinsurance
      when "deductible", "excess"
        :deductible
      else
        kind
      end
  end

  def cost_share_type_matches_scope
    return if scope.blank? || cost_share_type.blank?

    if scope.is_a?(PlanVersion) || scope.is_a?(PlanModule) || scope.is_a?(BenefitLimitGroup)
      return if deductible? || excess?

      errors.add(:cost_share_type, "must be deductible or excess for plan, module, and benefit limit group cost shares")
    elsif scope.is_a?(ModuleBenefit) || scope.is_a?(BenefitLimitRule)
      return if coinsurance?

      errors.add(:cost_share_type, "must be coinsurance for benefit and rule cost shares")
    end
  end

  def kind_family_alignment
    return if kind.blank? || cost_share_type.blank?

    if kind_coinsurance? && !coinsurance?
      errors.add(:kind, "coinsurance kind requires coinsurance cost share type")
      return
    end

    return unless kind_deductible? && !(deductible? || excess?)

    errors.add(:kind, "deductible kind requires deductible or excess cost share type")
  end

  def unit_matches_cost_share_type
    return if cost_share_type.blank? || unit.blank?

    if coinsurance? && !percent?
      errors.add(:unit, "must be percent for coinsurance")
      return
    end

    return unless (deductible? || excess?) && !amount?

    errors.add(:unit, "must be amount for deductible or excess")
  end

  def coinsurance_requires_percent_amount
    return unless coinsurance?
    return if amount.present?

    errors.add(:amount, "must be present for coinsurance")
  end

  def money_types_require_at_least_one_currency_amount
    return unless deductible? || excess?
    return if amount_values.any?

    errors.add(:base, "At least one currency amount (USD, GBP, or EUR) must be specified")
  end

  def member_cap_pairing
    cap_amount_present = cap_amount_values.any?
    cap_period_present = cap_period.present?

    return if cap_amount_present == cap_period_present

    errors.add(:base, "At least one cap currency amount (USD, GBP, or EUR) must be specified") unless cap_amount_present
    errors.add(:cap_period, "must be present when cap amount is provided") unless cap_period_present
  end
end
