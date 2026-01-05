FactoryBot.define do
  factory :plan do
    insurer
    name { "MyString" }

    transient do
      build_version { true }
      skip_autobuild { false }
      version_year { 1 }
      min_age { 1 }
      max_age { 1 }
      children_only_allowed { false }
      published { false }
      policy_type { :company }
      last_reviewed_at { Date.parse("2025-10-06") }
      next_review_due { Date.parse("2025-10-06") }
      review_notes { "MyText" }
    end

    after(:build) do |plan, evaluator|
      plan.skip_plan_version_autobuild = evaluator.skip_autobuild
      next if plan.current_plan_version || !evaluator.build_version

      plan.build_current_plan_version(
        version_year: evaluator.version_year,
        min_age: evaluator.min_age,
        max_age: evaluator.max_age,
        children_only_allowed: evaluator.children_only_allowed,
        published: evaluator.published,
        policy_type: evaluator.policy_type,
        last_reviewed_at: evaluator.last_reviewed_at,
        next_review_due: evaluator.next_review_due,
        review_notes: evaluator.review_notes,
        current: true
      )
    end

    trait :with_deductible do
      after(:create) do |plan|
        create(:cost_share, scope: plan.current_plan_version, cost_share_type: :deductible, amount: 1000, per: :per_year, currency: "USD")
      end
    end

    trait :with_coinsurance do
      after(:create) do |plan|
        create(:cost_share, scope: plan.current_plan_version, cost_share_type: :coinsurance, amount: 10, unit: :percent, per: :per_visit)
      end
    end

    trait :with_excess do
      after(:create) do |plan|
        create(:cost_share, scope: plan.current_plan_version, cost_share_type: :excess, amount: 25, per: :per_visit, currency: "USD")
      end
    end

    trait :with_all_cost_shares do
      after(:create) do |plan|
        create(:cost_share, scope: plan.current_plan_version, cost_share_type: :deductible, amount: 1000, per: :per_year, currency: "USD")
        create(:cost_share, scope: plan.current_plan_version, cost_share_type: :coinsurance, amount: 10, unit: :percent, per: :per_visit)
        create(:cost_share, scope: plan.current_plan_version, cost_share_type: :excess, amount: 25, per: :per_visit, currency: "USD")
      end
    end
  end
end
