class ComparisonWizardFlow
  attr_reader :progress

  def initialize(progress)
    @progress = progress
  end

  def steps
    %w[
      plan_selection
      comparison
    ]
  end

  def handle_step(params)
    case progress.current_step
    when "plan_selection" then save_plan_selection(params[:plan_selection])
    when "comparison" then save_comparison(params[:comparison])
    else
      WizardStepResult.new(success: true)
    end
  end

  def presenter_for(current_step)
    case current_step
    when "plan_selection"
      WizardProgresses::Comparison::PlanSelectionPresenter.new(progress)
    when "module_selection"
      WizardProgresses::Comparison::PlanSelectionPresenter.new(progress)
    when "comparison"
      WizardProgresses::Comparison::ComparisonPresenter.new(progress)
    else
      nil
    end
  end

  private

  def save_plan_selection(_params)
    WizardStepResult.new(success: true)
  end

  def save_comparison(_params)
    WizardStepResult.new(success: true)
  end
end
