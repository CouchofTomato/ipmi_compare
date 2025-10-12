FactoryBot.define do
  factory :benefit_limit_group do
    plan_module { nil }
    name { "MyString" }
    limit_usd { "9.99" }
    limit_gbp { "9.99" }
    limit_eur { "9.99" }
    limit_unit { "MyString" }
    notes { "MyText" }
  end
end
