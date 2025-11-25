class RemoveCategoryFromBenefits < ActiveRecord::Migration[8.1]
  def change
    remove_column :benefits, :category, :integer
  end
end
