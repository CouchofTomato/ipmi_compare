class CreateBenefitLimitGroupRules < ActiveRecord::Migration[8.1]
  def change
    create_table :benefit_limit_group_rules do |t|
      t.references :benefit_limit_group, null: false, foreign_key: true, index: true
      t.integer :rule_type, null: false, default: 0
      t.decimal :amount_usd, precision: 12, scale: 2
      t.decimal :amount_gbp, precision: 12, scale: 2
      t.decimal :amount_eur, precision: 12, scale: 2
      t.decimal :quantity_value, precision: 12, scale: 2
      t.integer :quantity_unit_kind
      t.string :quantity_unit_custom
      t.integer :period_kind, null: false, default: 0
      t.integer :period_value
      t.integer :position, null: false, default: 0
      t.text :notes

      t.timestamps
    end

    add_index :benefit_limit_group_rules, [ :benefit_limit_group_id, :position ], name: "idx_blgr_on_group_and_position"
    add_index :benefit_limit_group_rules, :rule_type
    add_index :benefit_limit_group_rules, :period_kind

    add_column :benefit_limit_groups, :wording_override, :text
  end
end
