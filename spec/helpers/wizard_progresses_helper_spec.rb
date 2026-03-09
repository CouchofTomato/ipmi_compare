require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the WizardProgressesHelper. For example:
#
# describe WizardProgressesHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe WizardProgressesHelper, type: :helper do
  describe "#shared_limit_rule_text" do
    it "renders amount rule text" do
      rule = build(:benefit_limit_group_rule, amount_gbp: 2500, amount_usd: nil, period_kind: :policy_year)

      expect(helper.shared_limit_rule_text(rule)).to eq("£2,500 per policy year")
    end

    it "renders usage rule text with rolling period" do
      rule = build(:benefit_limit_group_rule, :usage_rule, quantity_value: 15, quantity_unit_kind: :consultation, period_kind: :rolling_days, period_value: 30)

      expect(helper.shared_limit_rule_text(rule)).to eq("15 consultations in a 30 day period")
    end
  end
end
