require "set"

class ComparisonBuilder
  def initialize(progress)
    @progress = progress
  end

  def build
    selections = progress.comparison_plan_selections
    return empty_payload if selections.empty?

    plans_by_id =
      Plan.includes(:insurer, current_plan_version: { plan_modules: { module_benefits: [ :benefit, :benefit_limit_group ] } })
        .where(id: selections.map { |selection| selection["plan_id"] }.compact)
        .index_by(&:id)

    seen_selection_ids = Set.new

    selection_columns = selections.filter_map do |selection|
      plan = plans_by_id[selection["plan_id"].to_i]
      next unless plan&.current_plan_version

      selection_id = selection["id"]
      next unless selection_id.present?
      next if seen_selection_ids.include?(selection_id)

      seen_selection_ids << selection_id
      module_ids = selection.fetch("module_groups", {}).to_h.values.map(&:to_i).uniq

      {
        selection_id: selection_id,
        plan_id: plan.id,
        plan_version_id: plan.current_plan_version.id,
        plan_name: plan.name,
        insurer_name: plan.insurer.name,
        policy_type: plan.current_plan_version.policy_type,
        module_ids: module_ids
      }
    end

    module_benefits_by_selection =
      selection_columns.to_h do |selection|
        plan = plans_by_id[selection[:plan_id]]
        modules = plan.current_plan_version.plan_modules.select { |plan_module| selection[:module_ids].include?(plan_module.id) }
        [ selection[:selection_id], modules.flat_map(&:module_benefits) ]
      end

    categories =
      CoverageCategory.order(:position, :name).filter_map do |category|
        benefits = benefits_for_category(category, selection_columns, module_benefits_by_selection)
        next if benefits.empty?

        { id: category.id, name: category.name, benefits: benefits }
      end

    {
      selections: selection_columns,
      categories: categories
    }
  end

  private

  attr_reader :progress

  def benefits_for_category(category, selection_columns, module_benefits_by_selection)
    Benefit.where(coverage_category_id: category.id).order(:name).map do |benefit|
      {
        id: benefit.id,
        name: benefit.name,
        per_selection: selection_columns.to_h do |selection|
          [ selection[:selection_id], module_benefit_entries(benefit.id, module_benefits_by_selection[selection[:selection_id]]) ]
        end
      }
    end
  end

  def module_benefit_entries(benefit_id, module_benefits)
    Array(module_benefits)
      .select { |module_benefit| module_benefit.benefit_id == benefit_id }
      .sort_by(&:weighting)
      .map do |module_benefit|
        {
          module_benefit_id: module_benefit.id,
          plan_module_id: module_benefit.plan_module_id,
          plan_module_name: module_benefit.plan_module.name,
          coverage_description: module_benefit.coverage_description,
          limit_usd: module_benefit.limit_usd,
          limit_gbp: module_benefit.limit_gbp,
          limit_eur: module_benefit.limit_eur,
          limit_unit: module_benefit.limit_unit,
          waiting_period_months: module_benefit.waiting_period_months,
          interaction_type: module_benefit.interaction_type,
          benefit_limit_group_name: module_benefit.benefit_limit_group&.name
        }
      end
  end

  def empty_payload
    { selections: [], categories: [] }
  end
end
