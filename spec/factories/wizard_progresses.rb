FactoryBot.define do
  factory :wizard_progress do
    wizard_type { "plan_onboarding" }
    association :subject, factory: :plan
    user
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

    trait :plan_comparison do
      wizard_type { "plan_comparison" }
      subject { nil }
      current_step { "plan_selection" }
      step_order { 0 }
      metadata { {} }
      state { {} }
    end
  end
end
