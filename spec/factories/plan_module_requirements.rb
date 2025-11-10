FactoryBot.define do
  factory :plan_module_requirement do
    association :plan

    # The module that has the requirement
    association :module, factory: :plan_module

    # The module required in order to select the above module
    association :requires_module, factory: :plan_module

    # Ensure both modules belong to the same plan
    after(:build) do |req|
      req.module.plan = req.plan
      req.requires_module.plan = req.plan
    end
  end
end
