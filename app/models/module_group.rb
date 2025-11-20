class ModuleGroup < ApplicationRecord
  #== Associations ===========================================================
  belongs_to :plan

  #= Validations ===========================================================
  validates :name, presence: true
end
