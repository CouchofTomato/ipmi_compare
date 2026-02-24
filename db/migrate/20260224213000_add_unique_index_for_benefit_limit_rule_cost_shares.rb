class AddUniqueIndexForBenefitLimitRuleCostShares < ActiveRecord::Migration[8.1]
  def change
    add_index :cost_shares,
              [ :scope_type, :scope_id ],
              unique: true,
              where: "scope_type = 'BenefitLimitRule'",
              name: "index_cost_shares_unique_benefit_limit_rule_scope"
  end
end
