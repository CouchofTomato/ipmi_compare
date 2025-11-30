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

  def handle_step(params)
    case progress.current_step
    when "plan_selection" then save_plan_selection(params[:plan_selection])
    when "module_selection" then save_module_selection(params[:module_selection])
    when "comparison" then save_comparison(params[:comparison])
    else
      WizardStepResult.new(success: true)
    end
  end

  def presenter_for(current_step)
    case current_step
    when "plan_selection"
      PlanSelectionPresenter.new(progress)
    when "module_selection"
      ModuleSelectionPresenter.new(progress)
    when "comparison"
      ComparisonPresenter.new(progress)
    else
      nil
    end
  end
end
