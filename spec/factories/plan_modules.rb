FactoryBot.define do
  factory :plan_module do
    plan
    name { "MyString" }
    is_core { false }
    module_group

    trait :with_depends_on_module do
      after(:create) do |plan_module|
        plan_module.depends_on_module = create(:plan_module)
      end
    end
  end
end
