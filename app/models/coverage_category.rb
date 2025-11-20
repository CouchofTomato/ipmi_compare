class CoverageCategory < ApplicationRecord
  has_and_belongs_to_many :plan_modules
  has_many :module_benefits

  validates :name, presence: true, uniqueness: true
  validates :position, presence: true
end
