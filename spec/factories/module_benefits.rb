FactoryBot.define do
  factory :module_benefit do
    plan_module { nil }
    benefit { nil }
    coverage_description { "MyString" }
    limit_usd { "9.99" }
    limit_gbp { "9.99" }
    limit_eur { "9.99" }
    limit_unit { "MyString" }
    sub_limit_description { "MyString" }
    benefit_limit_group { nil }
  end
end
