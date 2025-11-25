class WizardProgress < ApplicationRecord
  belongs_to :subject, polymorphic: true, optional: true
  belongs_to :user
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
  validates :wizard_type, uniqueness: {
    scope: %i[subject_type subject_id],
    conditions: -> { where.not(subject_id: nil) }
  }

  def flow
    WizardFlow.for(self)
  end

  def steps
    flow.steps
  end

  def current_step_index
    steps.index(current_step) || 0
  end

  def next_step
    steps[current_step_index + 1]
  end

  def previous_step
    steps[current_step_index - 1] unless current_step_index.zero?
  end

  def progress
    ((current_step_index.to_f / (steps.size - 1)) * 100).round
  end
end
