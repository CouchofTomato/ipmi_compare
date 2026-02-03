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

      limit_value = entry[:limit_gbp] || entry[:limit_usd] || entry[:limit_eur]
      limit_currency =
        if entry[:limit_gbp].present?
          "GBP"
        elsif entry[:limit_usd].present?
          "USD"
        elsif entry[:limit_eur].present?
          "EUR"
        end

      if limit_value.present? || entry[:limit_unit].present?
        limit_label = +"Limit: "
        limit_label << "#{limit_currency}" if limit_currency.present?
        limit_label << "#{limit_value || 'N/A'}"
        limit_label << " #{entry[:limit_unit]}" if entry[:limit_unit].present?
        lines << limit_label
      end

      if entry[:waiting_period_months].present?
        lines << "Waiting: #{entry[:waiting_period_months]} months"
      end

      if entry[:benefit_limit_group_name].present?
        lines << "Shared limit: #{entry[:benefit_limit_group_name]}"
      end

      lines.join("\n")
    end
  end
end
