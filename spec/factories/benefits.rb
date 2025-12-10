FactoryBot.define do
  factory :benefit do
    sequence(:name) { |n| "Benefit_#{n}" }
    description { "Description of the benefit" }
    coverage_category
  end
end
