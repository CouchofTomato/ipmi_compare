class Insurer < ApplicationRecord
  has_one_attached :logo
  has_many :plans, dependent: :destroy

  validates :name, presence: true
  validates :jurisdiction, presence: true
end
