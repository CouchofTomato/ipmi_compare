class Insurer < ApplicationRecord
  validates :name, presence: true
  validates :jurisdiction, presence: true
end
