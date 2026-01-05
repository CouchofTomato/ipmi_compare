class GeographicCoverArea < ApplicationRecord
  has_many :plan_geographic_cover_areas, dependent: :destroy
  has_many :plan_versions, through: :plan_geographic_cover_areas
  has_many :plans, through: :plan_versions

  validates :name, presence: true
  validates :code, presence: true
end
