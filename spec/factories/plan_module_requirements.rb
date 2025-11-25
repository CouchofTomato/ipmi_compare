FactoryBot.define do
  factory :plan_module_requirement do
    plan

    # The module that has the requirement
    dependent_module { association :plan_module, plan: plan }

    # The module required in order to select the above module
    required_module { association :plan_module, plan: plan }
  end
end
