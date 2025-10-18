FactoryBot.define do
  factory :plan_module do
    plan
    module_group
    name { "MyString" }
    is_core { false }

    overall_limit_usd { nil }
    overall_limit_gbp { nil }
    overall_limit_eur { nil }
    overall_limit_unit { nil }
    overall_limit_notes { nil }

    trait :core do
      is_core { true }
      name { "Core Inpatient Module" }
    end

    trait :with_limits do
      overall_limit_usd { 50_000 }
      overall_limit_gbp { 35_000 }
      overall_limit_eur { 38_000 }
      overall_limit_unit { "per year" }
      overall_limit_notes { "Applies to all outpatient benefits" }
    end

    trait :with_dependencies do
      after(:create) do |plan_module|
        create(:plan_module, plan: plan_module.plan, module_group: plan_module.module_group)
      end
    end

    trait :with_depends_on_module do
      after(:create) do |plan_module|
        plan_module.depends_on_module = create(:plan_module)
      end
    end

    trait :with_deductible do
      after(:create) do |plan_module|
        create(:cost_share, scope: plan_module, cost_share_type: :deductible, amount: 1000, per: :per_year, currency: "USD")
      end
    end

    trait :with_coinsurance do
      after(:create) do |plan_module|
        create(:cost_share, scope: plan_module, cost_share_type: :coinsurance, amount: 10, unit: :percent, per: :per_claim)
      end
    end

    trait :with_excess do
      after(:create) do |plan_module|
        create(:cost_share, scope: plan_module, cost_share_type: :excess, amount: 25, per: :per_visit, currency: "USD")
      end
    end

    trait :with_all_cost_shares do
      after(:create) do |plan_module|
        create(:cost_share, scope: plan_module, cost_share_type: :deductible, amount: 1000, per: :per_year, currency: "USD")
        create(:cost_share, scope: plan_module, cost_share_type: :coinsurance, amount: 10, unit: :percent, per: :per_claim)
        create(:cost_share, scope: plan_module, cost_share_type: :excess, amount: 25, per: :per_visit, currency: "USD")
      end
    end
  end
end
