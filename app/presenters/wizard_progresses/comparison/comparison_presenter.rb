module WizardProgresses
  module Comparison
    class ComparisonPresenter
      attr_reader :progress

      def initialize(progress)
        @progress = progress
      end

      def saved_plan_selections
        PlanSelectionPresenter.new(progress).saved_plan_selections
      end
    end
  end
end
