class PlanModule < ApplicationRecord
  belongs_to :plan
  belongs_to :module_group
  belongs_to :depends_on_module, class_name: "PlanModule", optional: true
  has_many :dependent_modules, class_name: "PlanModule", foreign_key: "depends_on_module_id", dependent: :nullify
  has_many :benefit_limit_groups, dependent: :destroy

  validates :name, presence: true
end
