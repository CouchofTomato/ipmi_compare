class Plan < ApplicationRecord
  belongs_to :insurer

  validates :name, presence: true
  validates :min_age, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :max_age, numericality: { greater_than_or_equal_to: 0, only_integer: true, allow_nil: true }
  validates_inclusion_of :children_only_allowed, in: [ true, false ]
  validates_inclusion_of :published, in: [ true, false ]
  validates :version_year, presence: true
  validates :policy_type, presence: true
  validates :next_review_due, presence: true
end
