FactoryBot.define do
  factory :wizard_progress do
    wizard_type { "plan_onboarding" }
    association :entity, factory: :plan
    current_step { "plan_details" }
    step_order { 1 }
    status { "in_progress" }
    started_at { Time.current - 5.days }
    last_interaction_at { Time.current }
    completed_at { Time.current }
    abandoned_at { nil }
    expires_at { Time.current + 7.days }
    last_event { "MyString" }
    last_actor_id { nil }
    metadata { {} }

    trait :with_last_actor do
      after(:build) { |wizard| wizard.last_actor_id ||= create(:user).id }
    end
  end
end
