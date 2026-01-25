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
    scope: %i[subject_type subject_id user_id],
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

  def plan_version
    return unless subject.is_a?(Plan)

    version_id = metadata&.fetch("plan_version_id", nil)
    version = subject.plan_versions.find_by(id: version_id) if version_id.present?
    version || subject.current_plan_version
  end

  def comparison_name_from_state
    return unless wizard_type == "plan_comparison"

    selections = state.fetch("plan_selections", [])
    list =
      case selections
      when Hash then selections.values
      when Array then selections
      else []
      end

    plan_ids = list.map { |selection| selection["plan_id"] }.compact.uniq
    return if plan_ids.empty?

    plans_by_id = Plan.where(id: plan_ids).index_by(&:id)
    names = plan_ids.filter_map { |id| plans_by_id[id]&.name }
    return if names.empty?

    if names.size == 1
      "Comparison - #{names.first}"
    elsif names.size == 2
      "#{names[0]} vs #{names[1]}"
    else
      "#{names[0]} vs #{names[1]} +#{names.size - 2}"
    end
  end
end
