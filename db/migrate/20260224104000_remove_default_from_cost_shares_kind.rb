class RemoveDefaultFromCostSharesKind < ActiveRecord::Migration[8.1]
  def change
    change_column_default :cost_shares, :kind, from: 0, to: nil
  end
end
