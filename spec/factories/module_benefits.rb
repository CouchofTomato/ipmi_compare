FactoryBot.define do
  factory :module_benefit do
    plan_module
    benefit
    coverage_description { "MyString" }
    limit_usd { nil }
    limit_gbp { nil }
    limit_eur { nil }
    limit_unit { nil }
    sub_limit_description { nil }
    benefit_limit_group { nil }
  end
end
