class AddMultiCurrencyAmountsToCostShares < ActiveRecord::Migration[8.1]
  def change
    add_column :cost_shares, :amount_usd, :decimal, precision: 12, scale: 2
    add_column :cost_shares, :amount_gbp, :decimal, precision: 12, scale: 2
    add_column :cost_shares, :amount_eur, :decimal, precision: 12, scale: 2

    add_column :cost_shares, :cap_amount_usd, :decimal, precision: 12, scale: 2
    add_column :cost_shares, :cap_amount_gbp, :decimal, precision: 12, scale: 2
    add_column :cost_shares, :cap_amount_eur, :decimal, precision: 12, scale: 2

    change_column_null :cost_shares, :amount, true
  end
end
