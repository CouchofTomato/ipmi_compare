module WizardProgressesHelper
  def shared_limit_group_text(group)
    return group.wording_override if group.wording_override.present?

    rule = group.primary_rule
    return "Not stated" unless rule

    shared_limit_rule_text(rule)
  end

  def shared_limit_rule_text(rule)
    case rule.rule_type
    when "amount"
      amount_text = shared_limit_amount_text(rule)
      return amount_text if amount_text.blank?

      [ amount_text, period_text_for(rule) ].compact.join(" ")
    when "usage"
      quantity = number_with_precision(rule.quantity_value, precision: 2, strip_insignificant_zeros: true)
      unit = rule.quantity_unit_label
      unit = unit.pluralize unless rule.quantity_value.to_d == 1

      [ "#{quantity} #{unit}", period_text_for(rule) ].compact.join(" ")
    when "as_charged"
      "As charged"
    when "not_stated"
      "Not stated"
    else
      "Not stated"
    end
  end

  private

  def shared_limit_amount_text(rule)
    parts = []

    parts << "#{format_currency_value("£", rule.amount_gbp)}" if rule.amount_gbp.present?
    parts << "#{format_currency_value("$", rule.amount_usd)}" if rule.amount_usd.present?
    parts << "#{format_currency_value("€", rule.amount_eur)}" if rule.amount_eur.present?

    parts.join(" / ")
  end

  def format_currency_value(symbol, amount)
    "#{symbol}#{number_with_precision(amount, precision: 2, delimiter: ",", strip_insignificant_zeros: true)}"
  end

  def period_text_for(rule)
    case rule.period_kind
    when "policy_year" then "per policy year"
    when "calendar_year" then "per calendar year"
    when "rolling_days" then "in a #{rule.period_value} day period"
    when "rolling_months" then "in a #{rule.period_value} month period"
    when "lifetime" then "per lifetime"
    end
  end
end
