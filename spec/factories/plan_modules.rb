FactoryBot.define do
  factory :plan_module do
    plan
    name { "MyString" }
    is_core { false }
    association :depends_on_module, factory: :plan_module
    module_group
  end
end
