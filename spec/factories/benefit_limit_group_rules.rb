FactoryBot.define do
  factory :benefit_limit_group_rule do
    association :benefit_limit_group
    rule_type { :amount }
    amount_usd { 2500 }
    amount_gbp { nil }
    amount_eur { nil }
    quantity_value { nil }
    quantity_unit_kind { nil }
    quantity_unit_custom { nil }
    period_kind { :policy_year }
    period_value { nil }
    position { 0 }
    notes { nil }

    trait :usage_rule do
      rule_type { :usage }
      amount_usd { nil }
      quantity_value { 20 }
      quantity_unit_kind { :session }
      period_kind { :policy_year }
    end
  end
end
