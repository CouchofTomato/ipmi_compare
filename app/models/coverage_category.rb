class CoverageCategory < ApplicationRecord
  has_and_belongs_to_many :plan_modules
  has_many :benefits, dependent: :restrict_with_exception
  has_many :module_benefits, through: :benefits

  validates :name, presence: true, uniqueness: true
  validates :position, presence: true
end
