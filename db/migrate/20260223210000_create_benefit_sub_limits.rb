class CreateBenefitSubLimits < ActiveRecord::Migration[8.1]
  def change
    create_table :benefit_sub_limits do |t|
      t.references :module_benefit, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.integer :limit_type, null: false
      t.decimal :limit_usd, precision: 12, scale: 2
      t.decimal :limit_gbp, precision: 12, scale: 2
      t.decimal :limit_eur, precision: 12, scale: 2
      t.decimal :percent, precision: 6, scale: 2
      t.string :unit
      t.text :notes
      t.integer :position, null: false, default: 0

      t.timestamps
    end
  end
end
