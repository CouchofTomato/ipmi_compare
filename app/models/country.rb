class Country < ApplicationRecord
  belongs_to :region

  validates :name, presence: true
  validates :code, presence: true
end
