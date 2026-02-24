class AddMemberCapFieldsToCostShares < ActiveRecord::Migration[8.1]
  def change
    add_column :cost_shares, :cap_amount_cents, :integer
    add_column :cost_shares, :cap_currency, :string
    add_column :cost_shares, :cap_period, :integer
  end
end
