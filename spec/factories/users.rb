FactoryBot.define do
  factory :user do
    email { "email@example.com" }
    password { "password" }
    admin { false }
  end
end
