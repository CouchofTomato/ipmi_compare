require 'rails_helper'

RSpec.describe "Homepage", type: :system do
  it "passes" do
    visit root_path

    expect(page).to have_content "Welcome!"
  end

  it "fails (and takes a screenshot)" do
    visit root_path

    expect(page).to_not have_content "Welcome!"
  end
end
