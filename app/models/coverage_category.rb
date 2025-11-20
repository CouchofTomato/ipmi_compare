class CoverageCategory < ApplicationRecord
  has_and_belongs_to_many :plan_modules
end
