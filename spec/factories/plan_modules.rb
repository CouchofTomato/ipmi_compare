FactoryBot.define do
  factory :plan_module do
    plan { nil }
    name { "MyString" }
    is_core { false }
    depends_on_module { nil }
    module_group { nil }
  end
end
