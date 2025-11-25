class WizardStepResult
  attr_reader :resource, :errors

  def initialize(success:, resource: nil, errors: [])
    @success  = success
    @resource = resource
    @errors   = errors
  end

  def success?
    @success
  end

  def failure?
    !@success
  end
end
