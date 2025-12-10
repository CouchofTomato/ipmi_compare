class AddCoverageCategoryToBenefits < ActiveRecord::Migration[7.1]
  def change
    add_reference :benefits, :coverage_category, null: false, foreign_key: true
  end
end
