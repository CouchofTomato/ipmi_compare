class PlanResidencyEligibility < ApplicationRecord
  belongs_to :plan_version
  delegate :plan, to: :plan_version

  validates :country_code, presence: true, inclusion: { in: ISO3166::Country.all.map(&:alpha2) }
end
