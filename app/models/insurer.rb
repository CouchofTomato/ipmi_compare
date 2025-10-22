class Insurer < ApplicationRecord
  has_one_attached :logo
  has_many :plans, dependent: :destroy

  validates :name, presence: true
  validates :jurisdiction, presence: true

  def country_name
    country = ISO3166::Country[jurisdiction]
    country.translations[I18n.locale.to_s] || country.common_name || country.iso_short_name
  end
end
