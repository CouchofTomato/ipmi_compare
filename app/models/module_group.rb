class ModuleGroup < ApplicationRecord
  #== Associations ===========================================================
  belongs_to :plan_version
  delegate :plan, to: :plan_version
  has_many :plan_modules, dependent: :destroy

  #= Validations ===========================================================
  validates :name, presence: true
end
