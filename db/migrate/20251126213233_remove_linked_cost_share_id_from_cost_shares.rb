class RemoveLinkedCostShareIdFromCostShares < ActiveRecord::Migration[8.1]
  def change
    remove_reference :cost_shares, :linked_cost_share, foreign_key: { to_table: :cost_shares }
  end
end
