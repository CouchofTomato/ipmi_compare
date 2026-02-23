class RefineBenefitLimitRulesForInsurerAmounts < ActiveRecord::Migration[8.1]
  def up
    rename_column :benefit_limit_rules, :amount_usd, :insurer_amount_usd
    rename_column :benefit_limit_rules, :amount_gbp, :insurer_amount_gbp
    rename_column :benefit_limit_rules, :amount_eur, :insurer_amount_eur

    rename_column :benefit_limit_rules, :cap_usd, :cap_insurer_amount_usd
    rename_column :benefit_limit_rules, :cap_gbp, :cap_insurer_amount_gbp
    rename_column :benefit_limit_rules, :cap_eur, :cap_insurer_amount_eur

    remove_column :benefit_limit_rules, :percent, :decimal

    # Re-map existing enum values so :as_charged and :not_stated stay aligned after removing :percent.
    execute <<~SQL.squish
      UPDATE benefit_limit_rules
      SET limit_type = CASE limit_type
        WHEN 1 THEN 2
        WHEN 2 THEN 1
        WHEN 3 THEN 2
        ELSE limit_type
      END
    SQL
  end

  def down
    add_column :benefit_limit_rules, :percent, :decimal, precision: 6, scale: 2

    # Restore previous enum mapping with a reserved slot for :percent.
    execute <<~SQL.squish
      UPDATE benefit_limit_rules
      SET limit_type = CASE limit_type
        WHEN 1 THEN 2
        WHEN 2 THEN 3
        ELSE limit_type
      END
    SQL

    rename_column :benefit_limit_rules, :insurer_amount_usd, :amount_usd
    rename_column :benefit_limit_rules, :insurer_amount_gbp, :amount_gbp
    rename_column :benefit_limit_rules, :insurer_amount_eur, :amount_eur

    rename_column :benefit_limit_rules, :cap_insurer_amount_usd, :cap_usd
    rename_column :benefit_limit_rules, :cap_insurer_amount_gbp, :cap_gbp
    rename_column :benefit_limit_rules, :cap_insurer_amount_eur, :cap_eur
  end
end
