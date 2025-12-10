class Benefit < ApplicationRecord
  belongs_to :coverage_category
  has_many :module_benefits, dependent: :destroy

  validates :name, presence: true
  validates :coverage_category, presence: true
end
