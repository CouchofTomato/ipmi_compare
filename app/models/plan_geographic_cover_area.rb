class PlanGeographicCoverArea < ApplicationRecord
  belongs_to :plan_version
  delegate :plan, to: :plan_version
  belongs_to :geographic_cover_area
end
