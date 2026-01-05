class PlanVersion < ApplicationRecord
  belongs_to :plan, inverse_of: :plan_versions

  has_many :plan_geographic_cover_areas, dependent: :destroy
  has_many :geographic_cover_areas, through: :plan_geographic_cover_areas
  has_many :plan_residency_eligibilities, dependent: :destroy
  has_many :plan_module_requirements, dependent: :destroy

  has_many :cost_shares, as: :scope, dependent: :destroy
  has_many :deductibles, -> { where(cost_share_type: :deductible) },
           class_name: "CostShare", as: :scope
  has_many :coinsurances, -> { where(cost_share_type: :coinsurance) },
           class_name: "CostShare", as: :scope
  has_many :excesses, -> { where(cost_share_type: :excess) },
           class_name: "CostShare", as: :scope

  has_many :module_groups, -> { order(:position, :created_at) }, dependent: :destroy
  has_many :plan_modules, dependent: :destroy

  validates :version_year, presence: true
  validates :min_age, numericality: { greater_than_or_equal_to: 0, only_integer: true, allow_nil: true }
  validates :max_age, numericality: { greater_than_or_equal_to: 0, only_integer: true, allow_nil: true }
  validates_inclusion_of :children_only_allowed, in: [ true, false ]
  validates_inclusion_of :published, in: [ true, false ]
  validates :policy_type, presence: true
  validates :next_review_due, presence: true

  enum :policy_type, {
    individual: 0,
    company: 1,
    corporate: 2
  }

  scope :current, -> { where(current: true) }

  before_save :ensure_single_current, if: -> { current? && will_save_change_to_current? }

  private

  def ensure_single_current
    PlanVersion.where(plan_id:, current: true).where.not(id: id).update_all(current: false)
  end
end
