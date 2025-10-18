FactoryBot.define do
  factory :cost_share do
    # Polymorphic association — scope can be a Plan, PlanModule, or ModuleBenefit
    association :scope, factory: :plan_module

    cost_share_type { :deductible }     # enum: { deductible: 0, excess: 1, coinsurance: 2 }
    amount           { 1000.00 }
    unit             { :amount }        # enum: { amount: 0, percent: 1 }
    per              { :per_year }      # enum: { per_claim: 0, per_year: 1 }
    currency         { "USD" }
    notes            { "Standard annual deductible" }
    linked_cost_share { nil }

    # --- Nested factories for common variants ---

    factory :excess_cost_share do
      cost_share_type { :excess }
      amount { 25.00 }
      unit   { :amount }
      per    { :per_visit }
      notes  { "Per outpatient visit excess" }
    end

    factory :coinsurance_cost_share do
      cost_share_type { :coinsurance }
      amount { 10.0 }
      unit   { :percent }
      per    { :per_claim }
      notes  { "10% outpatient coinsurance" }
    end

    factory :linked_cost_share do
      after(:create) do |cost_share|
        create(:cost_share, linked_cost_share: cost_share)
      end
    end
  end
end
