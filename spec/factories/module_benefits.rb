FactoryBot.define do
  factory :module_benefit do
    plan_module
    benefit
    coverage_description { "MyString" }
    waiting_period_months { nil }
    benefit_limit_group { nil }
    interaction_type { :append } # append
    weighting { 0 }

    trait :with_deductible do
      after(:create) do |module_benefit|
        create(:cost_share, scope: module_benefit, cost_share_type: :coinsurance, amount: 10, unit: :percent, per: :per_year)
      end
    end

    trait :with_coinsurance do
      after(:create) do |module_benefit|
        create(:cost_share, scope: module_benefit, cost_share_type: :coinsurance, amount: 10, unit: :percent, per: :per_visit)
      end
    end

    trait :with_excess do
      after(:create) do |module_benefit|
        create(:cost_share, scope: module_benefit, cost_share_type: :coinsurance, amount: 25, unit: :percent, per: :per_visit)
      end
    end

    trait :with_all_cost_shares do
      after(:create) do |module_benefit|
        create(:cost_share, scope: module_benefit, cost_share_type: :coinsurance, amount: 10, unit: :percent, per: :per_visit)
      end
    end
  end
end
