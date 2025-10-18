FactoryBot.define do
  factory :plan do
    insurer
    name { "MyString" }
    min_age { 1 }
    max_age { 1 }
    children_only_allowed { false }
    version_year { 1 }
    published { false }
    policy_type { 1 }
    last_reviewed_at { "2025-10-06" }
    next_review_due { "2025-10-06" }
    review_notes { "MyText" }
    overall_limit_usd { 5_000_000 }
    overall_limit_gbp { 3_500_000 }
    overall_limit_eur { 3_800_000 }
    overall_limit_unit { "per year" }
    overall_limit_notes { nil }
    overall_limit_unlimited { false }

    trait :unlimited do
      overall_limit_unlimited { true }
      overall_limit_usd { nil }
      overall_limit_gbp { nil }
      overall_limit_eur { nil }
      overall_limit_notes { "Unlimited coverage" }
    end

    trait :with_deductible do
      after(:create) do |plan|
        create(:cost_share, scope: plan, cost_share_type: :deductible, amount: 1000, per: :per_year, currency: "USD")
      end
    end

    trait :with_coinsurance do
      after(:create) do |plan|
        create(:cost_share, scope: plan, cost_share_type: :coinsurance, amount: 10, unit: :percent, per: :per_visit)
      end
    end

    trait :with_excess do
      after(:create) do |plan|
        create(:cost_share, scope: plan, cost_share_type: :excess, amount: 25, per: :per_visit, currency: "USD")
      end
    end

    trait :with_all_cost_shares do
      after(:create) do |plan|
        create(:cost_share, scope: plan, cost_share_type: :deductible, amount: 1000, per: :per_year, currency: "USD")
        create(:cost_share, scope: plan, cost_share_type: :coinsurance, amount: 10, unit: :percent, per: :per_visit)
        create(:cost_share, scope: plan, cost_share_type: :excess, amount: 25, per: :per_visit, currency: "USD")
      end
    end
  end
end
