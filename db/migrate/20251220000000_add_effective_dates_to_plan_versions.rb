class AddEffectiveDatesToPlanVersions < ActiveRecord::Migration[8.1]
  class PlanVersion < ApplicationRecord
    self.table_name = "plan_versions"
  end

  def up
    add_column :plan_versions, :effective_on, :date
    add_column :plan_versions, :effective_through, :date

    PlanVersion.reset_column_information
    PlanVersion.find_each do |version|
      next if version.effective_on.present?

      version.update_columns(effective_on: Date.new(version.version_year, 1, 1))
    end

    change_column_null :plan_versions, :effective_on, false
  end

  def down
    remove_column :plan_versions, :effective_on
    remove_column :plan_versions, :effective_through
  end
end
