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
  end
end
