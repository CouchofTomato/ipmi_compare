class ComparisonWizardFlow
  attr_reader :progress

  def initialize(progress)
    @progress = progress
  end

  def steps
    %w[
      plan_selection
      module_selection
      comparison
    ]
  end
end
