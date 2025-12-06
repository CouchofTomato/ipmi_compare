module WizardProgresses
  module Comparison
    class PlanSelectionPresenter
      attr_reader :progress

      def initialize(progress)
        @progress = progress
      end

      def plans
        Plan.includes(:plan_modules)
      end
    end
  end
end
