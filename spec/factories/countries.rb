FactoryBot.define do
  factory :country do
    name { "MyString" }
    code { "MyString" }
    region { nil }
    notes { "MyText" }
  end
end
