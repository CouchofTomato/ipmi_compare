class MakePlanVersionMinAgeNullable < ActiveRecord::Migration[8.1]
  def up
    change_column_default :plan_versions, :min_age, from: 0, to: nil
    change_column_null :plan_versions, :min_age, true
  end

  def down
    change_column_null :plan_versions, :min_age, false
    change_column_default :plan_versions, :min_age, from: nil, to: 0
    execute <<~SQL.squish
      UPDATE plan_versions SET min_age = 0 WHERE min_age IS NULL;
    SQL
  end
end
