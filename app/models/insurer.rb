class Insurer < ApplicationRecord
  has_many :plans, dependent: :destroy

  validates :name, presence: true
  validates :jurisdiction, presence: true
end
