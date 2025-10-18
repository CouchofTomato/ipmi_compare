class PlanModule < ApplicationRecord
  belongs_to :plan
  belongs_to :module_group
  belongs_to :depends_on_module, class_name: "PlanModule", optional: true

  has_many :dependent_modules, class_name: "PlanModule", foreign_key: "depends_on_module_id", dependent: :nullify

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
