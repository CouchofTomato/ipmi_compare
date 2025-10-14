class CreateBenefits < ActiveRecord::Migration[8.0]
  def change
    create_table :benefits do |t|
      t.string :name, null: false
      t.integer :category, null: false
      t.text :description, null: true

      t.timestamps
    end
  end
end
