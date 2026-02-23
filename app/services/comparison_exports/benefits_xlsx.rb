module ComparisonExports
  class BenefitsXlsx
    def initialize(comparison_data)
      @comparison_data = comparison_data
    end

    def selections
      comparison_data[:selections] || []
    end

    def categories(exclude_uncovered: false)
      raw_categories = comparison_data[:categories] || []
      return raw_categories unless exclude_uncovered

      selection_ids = selections.map { |selection| selection[:selection_id] }

      raw_categories.filter_map do |category|
        benefits =
          category[:benefits].select do |benefit|
            selection_ids.any? do |selection_id|
              Array(benefit[:per_selection][selection_id]).any?
            end
          end

        next if benefits.empty?

        category.merge(benefits: benefits)
      end
    end

    def cell_text(entries)
      return "Not included" if entries.blank?

      Array(entries).map { |entry| entry_text(entry) }.join("\n\n")
    end

    private

    attr_reader :comparison_data

    def entry_text(entry)
      lines = []
      lines << entry[:plan_module_name].to_s if entry[:plan_module_name].present?
      lines << entry[:coverage_description].to_s if entry[:coverage_description].present?

      benefit_level_rules = entry[:benefit_level_limit_rules].to_a
      lines << entry[:cost_share_text] if benefit_level_rules.empty? && entry[:cost_share_text].present?

      benefit_level_rules.each_with_index do |rule, index|
        formatted_rule = format_rule(rule)
        formatted_rule = combine_cost_share_and_rule(entry[:cost_share_text], formatted_rule, rule) if index.zero?
        lines << formatted_rule
      end

      entry[:itemised_limit_rules].to_a.each do |rule|
        lines << "#{rule[:name]}: #{format_rule(rule)}"
      end

      if entry[:waiting_period_months].present?
        lines << "Waiting: #{entry[:waiting_period_months]} months"
      end

      if entry[:benefit_limit_group_name].present?
        lines << "Shared limit: #{entry[:benefit_limit_group_name]}"
      end

      lines.join("\n")
    end

    def format_rule(rule)
      base =
        case rule[:limit_type]
        when "amount"
          limit_lines(rule[:insurer_amount_usd], rule[:insurer_amount_gbp], rule[:insurer_amount_eur], rule[:unit]).join(" / ")
        when "as_charged"
          "As charged"
        when "not_stated"
          "Not stated"
        end

      cap = cap_lines(rule[:cap_insurer_amount_usd], rule[:cap_insurer_amount_gbp], rule[:cap_insurer_amount_eur], rule[:cap_unit]).join(" / ")
      result = base.to_s
      result = "#{result}, up to #{cap}" if cap.present?
      result = "#{result} (#{rule[:notes]})" if rule[:notes].present?
      result
    end

    def combine_cost_share_and_rule(cost_share_text, rule_text, rule)
      return rule_text if cost_share_text.blank?
      return "#{cost_share_text}, #{rule_text}" unless rule[:limit_type] == "amount" && rule[:cap_insurer_amount_usd].blank? && rule[:cap_insurer_amount_gbp].blank? && rule[:cap_insurer_amount_eur].blank?
      return "#{cost_share_text}, up to #{rule_text}" if rule[:unit].to_s.match?(/per policy year|per year/i)

      "#{cost_share_text}, #{rule_text}"
    end

    def limit_lines(insurer_amount_usd, insurer_amount_gbp, insurer_amount_eur, unit)
      currency_lines(insurer_amount_usd, insurer_amount_gbp, insurer_amount_eur).map do |line|
        [ line, unit ].compact.join(" ")
      end
    end

    def cap_lines(cap_insurer_amount_usd, cap_insurer_amount_gbp, cap_insurer_amount_eur, cap_unit)
      currency_lines(cap_insurer_amount_usd, cap_insurer_amount_gbp, cap_insurer_amount_eur).map do |line|
        [ line, cap_unit ].compact.join(" ")
      end
    end

    def currency_lines(usd, gbp, eur)
      [
        [ "USD", usd ],
        [ "GBP", gbp ],
        [ "EUR", eur ]
      ].filter_map do |currency, amount|
        next if amount.blank?
        "#{currency} #{format('%.2f', amount)}"
      end
    end
  end
end
