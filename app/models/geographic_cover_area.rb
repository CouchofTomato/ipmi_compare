class GeographicCoverArea < ApplicationRecord
  has_many :plan_geographic_cover_areas, dependent: :destroy
  has_many :plans, through: :plan_geographic_cover_areas

  validates :name, presence: true
  validates :code, presence: true
end
