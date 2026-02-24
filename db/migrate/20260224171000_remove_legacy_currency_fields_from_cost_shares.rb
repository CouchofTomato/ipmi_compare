class RemoveLegacyCurrencyFieldsFromCostShares < ActiveRecord::Migration[8.1]
  def change
    remove_column :cost_shares, :currency, :string
    remove_column :cost_shares, :cap_amount_cents, :integer
    remove_column :cost_shares, :cap_currency, :string
  end
end
