class AddCoverageCategoryToModuleBenefits < ActiveRecord::Migration[8.1]
  def change
    add_reference :module_benefits, :coverage_category, null: false, foreign_key: true
  end
end
