class CreateCostShares < ActiveRecord::Migration[8.0]
  def change
    create_table :cost_shares do |t|
      t.references :scope, polymorphic: true, null: false
      t.integer :cost_share_type, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.integer :unit, null: false
      t.integer :per, null: false
      t.string :currency
      t.text :notes
      t.references :linked_cost_share, foreign_key: { to_table: :cost_shares }, type: :bigint

      t.timestamps
    end
  end
end
