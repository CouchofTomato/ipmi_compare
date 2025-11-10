class PlanModuleRequirement < ApplicationRecord
  belongs_to :plan
  belongs_to :module
  belongs_to :requires_module
end
