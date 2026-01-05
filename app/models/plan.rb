class Plan < ApplicationRecord
  attr_accessor :skip_plan_version_autobuild

  belongs_to :insurer

  has_many :plan_versions, inverse_of: :plan, dependent: :destroy
  has_one :current_plan_version,
          -> { where(current: true) },
          class_name: "PlanVersion",
          inverse_of: :plan,
          dependent: :destroy,
          autosave: true

  before_validation :ensure_plan_version

  validates :name, presence: true

  delegate :version_year,
           :children_only_allowed,
           :children_only_allowed?,
           :min_age,
           :max_age,
           :policy_type,
           :published,
           :published?,
           :last_reviewed_at,
           :next_review_due,
           :review_notes,
           :plan_modules,
           :plan_module_ids,
           :module_groups,
           :module_group_ids,
           :geographic_cover_areas,
           :geographic_cover_area_ids,
           :cost_shares,
           :cost_share_ids,
           to: :current_plan_version,
           allow_nil: true

  validate :bubble_plan_version_errors

  def module_groups
    plan_version_for_assignment.module_groups
  end

  def plan_modules
    plan_version_for_assignment.plan_modules
  end

  def plan_module_ids
    plan_modules.pluck(:id)
  end

  def plan_geographic_cover_areas
    plan_version_for_assignment.plan_geographic_cover_areas
  end

  def plan_residency_eligibilities
    plan_version_for_assignment.plan_residency_eligibilities
  end

  def cost_shares
    plan_version_for_assignment.cost_shares
  end

  def cost_share_ids
    cost_shares.pluck(:id)
  end

  def deductibles
    plan_version_for_assignment.deductibles
  end

  def coinsurances
    plan_version_for_assignment.coinsurances
  end

  def excesses
    plan_version_for_assignment.excesses
  end

  def version_year=(value)
    plan_version_for_assignment.version_year = value
  end

  def children_only_allowed=(value)
    plan_version_for_assignment.children_only_allowed = ActiveModel::Type::Boolean.new.cast(value)
  end

  def min_age=(value)
    plan_version_for_assignment.min_age = value
  end

  def max_age=(value)
    plan_version_for_assignment.max_age = value
  end

  def policy_type=(value)
    plan_version_for_assignment.policy_type = value
  end

  def published=(value)
    plan_version_for_assignment.published = ActiveModel::Type::Boolean.new.cast(value)
  end

  def last_reviewed_at=(value)
    plan_version_for_assignment.last_reviewed_at = value
  end

  def next_review_due=(value)
    plan_version_for_assignment.next_review_due = value
  end

  def review_notes=(value)
    plan_version_for_assignment.review_notes = value
  end

  private

  def ensure_plan_version
    return current_plan_version if skip_plan_version_autobuild

    plan_version_for_assignment
  end

  def plan_version_for_assignment
    version =
      current_plan_version ||
        plan_versions.current.first ||
        plan_versions.first ||
        build_current_plan_version(current: true)

    self.current_plan_version ||= version if version
    version.current = true if version && !version.current?
    version
  end

  def bubble_plan_version_errors
    return if current_plan_version.nil?
    return if current_plan_version.valid?

    current_plan_version.errors.each do |error|
      if error.attribute == :base
        errors.add(:base, error.message)
      else
        errors.add(error.attribute, error.message)
      end
    end
  end
end
