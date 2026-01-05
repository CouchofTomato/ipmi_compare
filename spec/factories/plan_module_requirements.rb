FactoryBot.define do
  factory :plan_module_requirement do
    plan_version

    # The module that has the requirement
    dependent_module { association :plan_module, plan_version: plan_version, module_group: association(:module_group, plan_version: plan_version) }

    # The module required in order to select the above module
    required_module { association :plan_module, plan_version: plan_version, module_group: association(:module_group, plan_version: plan_version) }
  end
end
