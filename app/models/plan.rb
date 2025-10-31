class Plan < ApplicationRecord
  belongs_to :insurer

  has_many :plan_geographic_cover_areas, dependent: :destroy
  has_many :geographic_cover_areas, through: :plan_geographic_cover_areas

  has_many :plan_residency_eligibilities, dependent: :destroy

  has_many :cost_shares, as: :scope, dependent: :destroy
  has_many :deductibles, -> { where(cost_share_type: :deductible) },
           class_name: "CostShare", as: :scope
  has_many :coinsurances, -> { where(cost_share_type: :coinsurance) },
           class_name: "CostShare", as: :scope
  has_many :excesses, -> { where(cost_share_type: :excess) },
           class_name: "CostShare", as: :scope

  validates :name, presence: true
  validates :min_age, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :max_age, numericality: { greater_than_or_equal_to: 0, only_integer: true, allow_nil: true }
  validates_inclusion_of :children_only_allowed, in: [ true, false ]
  validates_inclusion_of :published, in: [ true, false ]
  validates :version_year, presence: true
  validates :policy_type, presence: true
  validates :next_review_due, presence: true
  validate :overall_limit_presence_rule

  enum :policy_type, {
    individual: 0,
    company: 1,
    corporate: 2
  }

  private

  def overall_limit_presence_rule
    # Skip validation if plan is marked as unlimited
    return if overall_limit_unlimited?

    # Ensure at least one monetary limit is provided
    if [ overall_limit_usd, overall_limit_gbp, overall_limit_eur ].all?(&:blank?)
      errors.add(:base, "Specify at least one overall limit or mark the plan as unlimited")
    end
  end
end
