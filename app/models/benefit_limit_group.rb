class BenefitLimitGroup < ApplicationRecord
  belongs_to :plan_module

  has_many :module_benefits, dependent: :destroy

  has_many :cost_shares, as: :scope, dependent: :destroy
  has_many :deductibles, -> { where(cost_share_type: :deductible) },
            class_name: "CostShare", as: :scope
  has_many :coinsurances, -> { where(cost_share_type: :coinsurance) },
            class_name: "CostShare", as: :scope
  has_many :excesses, -> { where(cost_share_type: :excess) },
            class_name: "CostShare", as: :scope

  validates :name, presence: true
  validates :limit_unit, presence: true
  validate :at_least_one_currency_limit_present

  private

  def at_least_one_currency_limit_present
    if [ limit_usd, limit_gbp, limit_eur ].all?(&:blank?)
      errors.add(:base, "At least one currency limit (USD, GBP, or EUR) must be specified")
    end
  end
end
