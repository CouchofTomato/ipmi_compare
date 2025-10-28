class PlanWizardFlow
  attr_reader :progress

  def initialize(progress)
    @progress = progress
  end

  def steps
    %w[ plan_residency geographic_cover_areas plan_modules module_benefits cost_shares review]
  end

  def handle_step(params)
    # Empty for now – logic will be added in next PR
  end
end
