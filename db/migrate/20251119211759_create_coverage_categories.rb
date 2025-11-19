class CreateCoverageCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :coverage_categories do |t|
      t.string :name, null: false
      t.integer :position, null: false

      t.timestamps
    end

    add_index :coverage_categories, :name, unique: true
    add_index :coverage_categories, :position
  end
end
