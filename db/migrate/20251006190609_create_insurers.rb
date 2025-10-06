class CreateInsurers < ActiveRecord::Migration[8.0]
  def change
    create_table :insurers do |t|
      t.string :name
      t.string :jurisdiction

      t.timestamps
    end
  end
end
