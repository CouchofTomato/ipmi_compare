class CreateCountries < ActiveRecord::Migration[8.0]
  def change
    create_table :countries do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.references :region, null: false, foreign_key: true
      t.text :notes

      t.timestamps
    end
  end
end
