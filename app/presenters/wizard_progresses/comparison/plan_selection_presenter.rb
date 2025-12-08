module WizardProgresses
  module Comparison
    class PlanSelectionPresenter
      attr_reader :progress

      def initialize(progress)
        @progress = progress
      end

      def plans
        Plan.includes(:plan_modules).order(:name)
      end

      def search(query)
        return Plan.none if query.blank?
        term = "%#{query.strip}%"
        Plan.includes(module_groups: :plan_modules)
          .joins(:insurer)
          .where("plans.name ILIKE :term OR insurers.name ILIKE :term", term:)
          .distinct
          .order("plans.name ASC")
      end

      def saved_plan_selections
        selections = normalized_plan_selections
        return [] if selections.empty?

        plan_ids = selections.map { |s| s["plan_id"] }.compact
        plans_by_id = Plan.includes(module_groups: :plan_modules).where(id: plan_ids).index_by(&:id)

        selections.filter_map do |selection|
          plan_id = selection["plan_id"].to_i
          plan = plans_by_id[plan_id]
          next unless plan

          chosen_modules = Array(selection["module_groups"]).to_h

          modules = chosen_modules.filter_map do |group_id, module_id|
            group = plan.module_groups.find { |g| g.id.to_s == group_id.to_s }
            mod = group&.plan_modules&.find { |pm| pm.id == module_id.to_i }
            next unless group && mod

            [ group, mod ]
          end

          { id: selection["id"] || selection[:id] || plan_id.to_s, plan:, modules: modules }
        end
      end

      private

      def normalized_plan_selections
        raw = progress.state["plan_selections"]
        case raw
        when Hash then raw.values
        when Array then raw
        else []
        end
      end
    end
  end
end
