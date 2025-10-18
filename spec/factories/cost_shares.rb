FactoryBot.define do
  factory :cost_share do
    scope { nil }
    cost_share_type { 1 }
    amount { "9.99" }
    unit { 1 }
    per { 1 }
    currency { "MyString" }
    notes { "MyText" }
    linked_cost_share_id { 1 }
  end
end
