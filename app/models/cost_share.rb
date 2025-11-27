class CostShare < ApplicationRecord
  # Virtual attributes used only for the wizard form selections
  attr_accessor :applies_to, :plan_module_id, :module_benefit_id, :benefit_limit_group_id

  belongs_to :scope, polymorphic: true

  has_many :cost_share_links, dependent: :destroy
  has_many :linked_cost_shares,
           through: :cost_share_links,
           source: :linked_cost_share

  # Reverse links where this cost share is the "linked" one
  has_many :reverse_cost_share_links,
           class_name: "CostShareLink",
           foreign_key: :linked_cost_share_id,
           dependent: :destroy

  has_many :parent_cost_shares,
           through: :reverse_cost_share_links,
           source: :cost_share

  enum :cost_share_type, {
    deductible: 0,
    excess: 1,
    coinsurance: 2
  }

  enum :unit, {
    amount: 0,
    percent: 1
  }

  enum :per, {
    per_visit: 0,
    per_condition: 1,
    per_year: 2
  }

  validates :scope, presence: true
  validates :cost_share_type, presence: true
  validates :amount, presence: true, numericality: true
  validates :unit, presence: true
  validates :per, presence: true
end
