class Plan < ApplicationRecord
  belongs_to :insurer

  has_many :plan_geographic_cover_areas, dependent: :destroy
  has_many :geographic_cover_areas, through: :plan_geographic_cover_areas

  has_many :plan_residency_eligibilities, dependent: :destroy
  has_many :countries, through: :plan_residency_eligibilities

  validates :name, presence: true
  validates :min_age, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :max_age, numericality: { greater_than_or_equal_to: 0, only_integer: true, allow_nil: true }
  validates_inclusion_of :children_only_allowed, in: [ true, false ]
  validates_inclusion_of :published, in: [ true, false ]
  validates :version_year, presence: true
  validates :policy_type, presence: true
  validates :next_review_due, presence: true

  enum :policy_type, {
    individual: 0,
    company: 1,
    corporate: 2
  }
end
