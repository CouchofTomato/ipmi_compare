class CreateCostShareLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :cost_share_links do |t|
      t.references :cost_share, null: false, foreign_key: { to_table: :cost_shares }
      t.references :linked_cost_share, null: false, foreign_key: { to_table: :cost_shares }
      t.integer :relationship_type, null: false, default: 2

      t.timestamps
    end

    add_index :cost_share_links,
              [ :cost_share_id, :linked_cost_share_id ],
              unique: true,
              name: "idx_cost_share_links_uniqueness"
  end
end
