class WizardFlow
  def self.for(wizard)
    case wizard.wizard_type
    when "plan_creation"
      PlanWizardFlow.new(wizard)
    else
      raise ArgumentError, "Unknown wizard type: #{wizard.wizard_type}"
    end
  end
end
