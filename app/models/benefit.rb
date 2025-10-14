class Benefit < ApplicationRecord
  enum :category, {
    inpatient: 0,
    outpatient: 1,
    therapies: 2,
    maternity: 3,
    dental: 4,
    optical: 5,
    medicines: 6,
    evacuation: 7,
    repatriation: 8,
    wellness: 9
  }

  validates :name, presence: true
  validates :category, presence: true
end
