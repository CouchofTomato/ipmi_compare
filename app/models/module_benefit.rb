class ModuleBenefit < ApplicationRecord
  belongs_to :plan_module
  belongs_to :benefit
  belongs_to :benefit_limit_group
end
