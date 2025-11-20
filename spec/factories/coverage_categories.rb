FactoryBot.define do
  factory :coverage_category do
    sequence(:name) { |n| "category_#{n}" }
    position { 0 }

    factory :coverage_category_with_plan_modules do
      transient do
        plan_modules_count { 3 }
      end

      after(:create) do |coverage_category, evaluator|
        create_list(:plan_module, evaluator.plan_modules_count, coverage_categories: [ coverage_category ])
      end
    end
  end
end
