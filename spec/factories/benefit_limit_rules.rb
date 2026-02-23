FactoryBot.define do
  factory :benefit_limit_rule do
    module_benefit
    scope { :benefit_level }
    name { "MRI scans" }
    limit_type { :amount }
    insurer_amount_usd { 500 }
    insurer_amount_gbp { nil }
    insurer_amount_eur { nil }
    unit { "per policy year" }
    cap_insurer_amount_usd { nil }
    cap_insurer_amount_gbp { nil }
    cap_insurer_amount_eur { nil }
    cap_unit { nil }
    notes { nil }
    position { 0 }

    after(:build) do |rule|
      next if rule.limit_type.to_s == "amount"

      rule.insurer_amount_usd = nil
      rule.insurer_amount_gbp = nil
      rule.insurer_amount_eur = nil
      rule.unit = nil
    end
  end
end
