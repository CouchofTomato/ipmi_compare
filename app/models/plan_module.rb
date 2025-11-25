class PlanModule < ApplicationRecord
  belongs_to :plan
  belongs_to :module_group

  has_many :module_benefits, dependent: :destroy
  has_many :benefits, through: :module_benefits

  has_and_belongs_to_many :coverage_categories

  has_many :benefit_limit_groups, dependent: :destroy

  has_many :cost_shares, as: :scope, dependent: :destroy
  has_many :deductibles, -> { where(cost_share_type: :deductible) },
           class_name: "CostShare", as: :scope
  has_many :coinsurances, -> { where(cost_share_type: :coinsurance) },
           class_name: "CostShare", as: :scope
  has_many :excesses, -> { where(cost_share_type: :excess) },
           class_name: "CostShare", as: :scope

  validates :name, presence: true
end
