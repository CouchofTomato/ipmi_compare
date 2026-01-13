FactoryBot.define do
  factory :plan_version do
    association :plan, build_version: false, skip_autobuild: true
    version_year { 2025 }
    effective_on { Date.new(version_year, 1, 1) }
    effective_through { nil }
    min_age { 0 }
    max_age { 65 }
    children_only_allowed { false }
    published { false }
    policy_type { :company }
    last_reviewed_at { Date.parse("2025-10-06") }
    next_review_due { Date.parse("2025-10-06") }
    review_notes { "MyText" }
    current { true }

    after(:build) do |plan_version|
      plan_version.plan.skip_plan_version_autobuild = true
      plan_version.plan.current_plan_version = plan_version
      plan_version.current = true if plan_version.current.nil?
    end
  end
end
