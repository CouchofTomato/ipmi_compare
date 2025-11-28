class ModuleGroup < ApplicationRecord
  #== Associations ===========================================================
  belongs_to :plan
  has_many :plan_modules, dependent: :destroy

  #= Validations ===========================================================
  validates :name, presence: true
end
