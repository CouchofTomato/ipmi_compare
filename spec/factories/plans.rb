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
      overall_limit_usd { nil }
      overall_limit_gbp { nil }
      overall_limit_eur { nil }
      overall_limit_notes { "Unlimited" }
    end
  end
end
