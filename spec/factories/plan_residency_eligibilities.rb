FactoryBot.define do
  factory :plan_residency_eligibility do
    plan
    country_code { "US" }
    notes { "MyText" }
  end
end
