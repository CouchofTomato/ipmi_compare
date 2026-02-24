class AddKindToCostShares < ActiveRecord::Migration[8.1]
  def up
    add_column :cost_shares, :kind, :integer, null: false, default: 0

    execute <<~SQL
      UPDATE cost_shares
      SET kind = 1
      WHERE scope_type IN ('ModuleBenefit', 'BenefitLimitRule')
    SQL
  end

  def down
    remove_column :cost_shares, :kind
  end
end
