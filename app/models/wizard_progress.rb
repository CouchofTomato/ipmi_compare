class WizardProgress < ApplicationRecord
  belongs_to :entity, polymorphic: true
  belongs_to :last_actor, class_name: "User", optional: true

  enum :status, {
    in_progress: "in_progress",
    complete:    "complete",
    abandoned:   "abandoned",
    expired:     "expired"
  }

  validates :wizard_type, presence: true
  validates :current_step, presence: true
  validates :started_at, presence: true
  validates :step_order, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :wizard_type, uniqueness: { scope: %i[entity_type entity_id] }
end
