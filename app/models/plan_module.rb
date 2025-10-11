class PlanModule < ApplicationRecord
  belongs_to :plan
  belongs_to :depends_on_module
  belongs_to :module_group
end
