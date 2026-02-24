require "rails_helper"

RSpec.describe "db/seeds.rb" do
  it "loads without errors" do
    expect { load Rails.root.join("db/seeds.rb") }.not_to raise_error
  end
end
