class PlanModuleRequirement < ApplicationRecord
  belongs_to :plan_version
  belongs_to :dependent_module, class_name: "PlanModule"
  belongs_to :required_module, class_name: "PlanModule"
  delegate :plan, to: :plan_version

  before_validation :apply_plan_version_from_modules
  validates :plan_version_id, presence: true
  validates :dependent_module_id, presence: true
  validates :required_module_id, presence: true

  validate :modules_belong_to_plan_version
  validate :not_self_referencing
  validate :no_reverse_cycle

  private

  def apply_plan_version_from_modules
    return if plan_version_id_changed? && plan_version_id.nil?

    self.plan_version ||= dependent_module&.plan_version || required_module&.plan_version
  end

  def modules_belong_to_plan_version
    return if dependent_module.nil? || required_module.nil?

    if dependent_module.plan_version != plan_version || required_module.plan_version != plan_version
      errors.add(:base, "Dependent and required modules must belong to the same plan version")
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
      plan_version: plan_version,
      dependent_module: required_module,
      required_module: dependent_module
    )
      errors.add(:base, "Circular dependency detected")
    end
  end
end
