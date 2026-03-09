FactoryBot.define do
  factory :benefit_limit_group do
    plan_module
    name { "MyString" }
    limit_usd { "9.99" }
    limit_gbp { "9.99" }
    limit_eur { "9.99" }
    limit_unit { "MyString" }
    wording_override { nil }
    notes { "MyText" }

    trait :with_shared_limit_rule do
      limit_usd { nil }
      limit_gbp { nil }
      limit_eur { nil }
      limit_unit { "structured" }

      after(:build) do |group|
        group.benefit_limit_group_rules << build(:benefit_limit_group_rule, benefit_limit_group: group)
      end
    end
  end
end
