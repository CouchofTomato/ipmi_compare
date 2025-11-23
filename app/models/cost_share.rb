class CostShare < ApplicationRecord
  # Virtual attributes used only for the wizard form selections
  attr_accessor :applies_to, :plan_module_id, :module_benefit_id

  belongs_to :scope, polymorphic: true
  belongs_to :linked_cost_share, class_name: "CostShare", optional: true

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
