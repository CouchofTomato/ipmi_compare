class PlanModuleRequirement < ApplicationRecord
  belongs_to :plan
  belongs_to :dependent_module, class_name: "PlanModule"
  belongs_to :required_module, class_name: "PlanModule"

  validates :plan_id, presence: true
  validates :dependent_module_id, presence: true
  validates :required_module_id, presence: true

  validate :modules_belong_to_plan
  validate :not_self_referencing
  validate :no_reverse_cycle

  private

  def modules_belong_to_plan
    return if dependent_module.nil? || required_module.nil?

    if dependent_module.plan != plan || required_module.plan != plan
      errors.add(:base, "Dependent and required modules must belong to the same plan")
    end
  end

  # Prevent a module from requiring itself
  def not_self_referencing
    return if dependent_module.blank? || required_module.blank?

    if dependent_module == required_module
      errors.add(:required_module_id, "cannot be the same as the dependent module")
    end
  end

  # Prevent immediate circular dependency: A→B and B→A
  def no_reverse_cycle
    if PlanModuleRequirement.exists?(
      plan: plan,
      dependent_module: required_module,
      required_module: dependent_module
    )
      errors.add(:base, "Circular dependency detected")
    end
  end
end
