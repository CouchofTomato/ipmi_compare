class Country < ApplicationRecord
  belongs_to :region

  has_many :plan_residency_eligibilities, dependent: :destroy
  has_many :plans, through: :plan_residency_eligibilities

  validates :name, presence: true
  validates :code, presence: true
end
