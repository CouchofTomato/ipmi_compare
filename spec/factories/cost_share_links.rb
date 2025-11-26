FactoryBot.define do
  factory :cost_share_link do
    association :cost_share
    association :linked_cost_share, factory: :cost_share
    relationship_type { :dependent }

    trait :shared_pool do
      relationship_type { :shared_pool }
    end

    trait :override do
      relationship_type { :override }
    end
  end
end
