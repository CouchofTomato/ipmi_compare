FactoryBot.define do
  factory :module_benefit do
    plan_module
    benefit
    coverage_category
    coverage_description { "MyString" }
    limit_usd { nil }
    limit_gbp { nil }
    limit_eur { nil }
    limit_unit { nil }
    sub_limit_description { nil }
    benefit_limit_group { nil }
    interaction_type { :append } # append
    weighting { 0 }

    trait :with_deductible do
      after(:create) do |module_benefit|
        create(:cost_share, scope: module_benefit, cost_share_type: :deductible, amount: 1000, per: :per_year, currency: "USD")
      end
    end

    trait :with_coinsurance do
      after(:create) do |module_benefit|
        create(:cost_share, scope: module_benefit, cost_share_type: :coinsurance, amount: 10, unit: :percent, per: :per_visit)
      end
    end

    trait :with_excess do
      after(:create) do |module_benefit|
        create(:cost_share, scope: module_benefit, cost_share_type: :excess, amount: 25, per: :per_visit, currency: "USD")
      end
    end

    trait :with_all_cost_shares do
      after(:create) do |module_benefit|
        create(:cost_share, scope: module_benefit, cost_share_type: :deductible, amount: 1000, per: :per_year, currency: "USD")
        create(:cost_share, scope: module_benefit, cost_share_type: :coinsurance, amount: 10, unit: :percent, per: :per_visit)
        create(:cost_share, scope: module_benefit, cost_share_type: :excess, amount: 25, per: :per_visit, currency: "USD")
      end
    end
  end
end
