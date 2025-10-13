class AddOverallLimitUnlimitedToPlans < ActiveRecord::Migration[8.0]
  def change
    add_column :plans, :overall_limit_unlimited, :boolean, default: false, null: false
  end
end
