class RemoveCoverageCategoryFromModuleBenefits < ActiveRecord::Migration[7.1]
  def change
    remove_reference :module_benefits, :coverage_category, foreign_key: true
  end
end
