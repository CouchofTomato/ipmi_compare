class CostShareLink < ApplicationRecord
  belongs_to :cost_share
  belongs_to :linked_cost_share, class_name: "CostShare"

  enum :relationship_type, {
    shared_pool: 0,   # same bucket, amounts reduce each other
    override: 1,      # one cost share replaces/supersedes another
    dependent: 2      # selecting A activates B, independent buckets
  }


  validates :cost_share, presence: true
  validates :linked_cost_share, presence: true
  validates :relationship_type, presence: true

  validate :cannot_link_to_self

  private

  def cannot_link_to_self
    if cost_share_id.present? && cost_share_id == linked_cost_share_id
      errors.add(:linked_cost_share, "cannot be the same as cost_share")
    end
  end
end
