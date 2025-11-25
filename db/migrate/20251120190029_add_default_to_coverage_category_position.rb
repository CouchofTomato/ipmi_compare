class AddDefaultToCoverageCategoryPosition < ActiveRecord::Migration[8.1]
  def change
    change_column_default :coverage_categories, :position, 0
  end
end
