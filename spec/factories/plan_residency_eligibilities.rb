FactoryBot.define do
  factory :plan_residency_eligibility do
    plan_version
    country_code { "US" }
    notes { "MyText" }
  end
end
